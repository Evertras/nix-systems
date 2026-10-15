{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.evertras.home.shell.mcp.tailscale;

  # One server per tailnet, each named `tailscale-<instance>`: that's the nix
  # key, claude file name / `paths` entry, and claude server name (so tools are
  # `mcp__tailscale-<instance>__*` and two tailnets never clash in one
  # sandbox).  As with the other fleet servers the container, and so the DNS
  # name, carries an extra `mcp-` prefix.
  fullName = name: "tailscale-${name}";
  containerName = name: "mcp-${fullName name}";

  # Shared by every instance; built once on first `mcp-up`.
  # tailscale-mcp only speaks stdio, so bridge it to streamable HTTP with
  # supergateway exactly like the github server.  The bridged child inherits
  # the container env, which is where the creds and filters live.
  image = "evertras-tailscale-mcp";
  dockerfile = ''
    FROM node:lts-slim
    RUN npm install -g supergateway @yawlabs/tailscale-mcp@${cfg.version}
    ENTRYPOINT ["supergateway"]
  '';

  mkServer = name: inst: {
    containerName = containerName name;
    inherit image;
    build = dockerfile;
    args = [
      "--stdio"
      "tailscale-mcp"
      "--outputTransport"
      "streamableHttp"
      "--streamableHttpPath"
      "/mcp"
      "--port"
      (toString cfg.port)
      "--host"
      "0.0.0.0"
    ];
    env = {
      TAILSCALE_READONLY = "1";
    }
    // optionalAttrs (inst.toolGroups != [ ]) {
      TAILSCALE_TOOLS = concatStringsSep "," inst.toolGroups;
    };
    # Mint the OAuth creds on the host; their stdout becomes the container's
    # env via the private env-file.  The tailnet defaults to the client's own,
    # so it needs no setting.
    prepare = ''
      client_id="$(${inst.oauthClientIdCommand})"
      client_secret="$(${inst.oauthClientSecretCommand})"
      printf 'TAILSCALE_OAUTH_CLIENT_ID=%s\n' "$client_id"
      printf 'TAILSCALE_OAUTH_CLIENT_SECRET=%s\n' "$client_secret"
    '';
  };
in
{
  options.evertras.home.shell.mcp.tailscale = {
    instances = mkOption {
      default = { };
      description = ''
        Read-only Tailscale MCP servers in the fleet, one per tailnet, keyed by
        a short instance name (YawLabs/tailscale-mcp, which talks to the
        Tailscale v2 admin API rather than a local tailscale CLI).  Each
        becomes container `mcp-tailscale-<name>` and claude config
        `...mcp.claude.paths."tailscale-<name>"` for wiring into a
        claude-sandbox profile's `mcp` list.

        Read-only is enforced in two independent places:

        1. The credential.  Each instance authenticates with an OAuth client
           created in that tailnet's admin console with read scopes only
           (`all:read`, or narrower).  This is the guarantee that holds even if
           the server's own filtering is wrong, since the token cannot write.
        2. `TAILSCALE_READONLY=1`, always set, which drops every tool without a
           read-only hint before claude ever sees it, so the agent isn't
           offered writes that would only fail with a 403.
      '';
      example = literalExpression ''
        {
          personal = {
            oauthClientIdCommand = "pass tailscale/MCP_OAUTH_CLIENT_ID";
            oauthClientSecretCommand = "pass tailscale/MCP_OAUTH_CLIENT_SECRET";
          };
        }
      '';
      type = types.attrsOf (
        types.submodule {
          options = {
            toolGroups = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [
                "status"
                "devices"
                "acl"
                "dns"
              ];
              description = ''
                Tool groups to load (`TAILSCALE_TOOLS`).  Empty uses the
                server's default (every group).  Read-only is always enforced
                on top of whichever groups are loaded.  Grant the OAuth client
                the read scopes for these groups (see the server's "OAuth
                scopes by tool group").
              '';
            };

            oauthClientIdCommand = mkOption {
              type = types.str;
              example = "pass tailscale/MCP_OAUTH_CLIENT_ID";
              description = ''
                Host command run by `mcp-up`; its stdout is the OAuth client id.
                The client should only have read scopes.
              '';
            };

            oauthClientSecretCommand = mkOption {
              type = types.str;
              example = "pass tailscale/MCP_OAUTH_CLIENT_SECRET";
              description = ''
                Host command run by `mcp-up`; its stdout is the OAuth client
                secret.  Like the github token, it lives only inside the
                container (via the private env-file) and is never exposed to
                claude-sandbox, which reaches the server over plain HTTP by
                name.
              '';
            };
          };
        }
      );
    };

    port = mkOption {
      type = types.port;
      default = 8400;
      description = ''
        Port every instance's container listens on for streamable HTTP (path
        `/mcp`).  Each container has its own DNS name, so instances can share
        it; claude reaches one at `http://mcp-tailscale-<name>:<port>/mcp`.
      '';
    };

    version = mkOption {
      type = types.str;
      default = "0.21.1";
      description = "@yawlabs/tailscale-mcp npm version baked into the image.";
    };
  };

  config = mkIf (cfg.instances != { }) {
    evertras.home.shell.mcp = {
      servers = mapAttrs' (n: inst: nameValuePair (fullName n) (mkServer n inst)) cfg.instances;

      # Matching claude MCP config files, reached by container DNS name.
      claude = {
        enable = true;
        files = mapAttrs' (
          n: _:
          nameValuePair (fullName n) {
            servers.${fullName n} = {
              type = "http";
              url = "http://${containerName n}:${toString cfg.port}/mcp";
            };
          }
        ) cfg.instances;
      };
    };

    # Tell the agent up front that Tailscale writes are not available, so it
    # explains instead of discovering it by failing, as with Linear.
    evertras.home.shell.claude-sandbox.extraInstructions = [
      ''
        The Tailscale MCP servers (`tailscale-<tailnet>`) are read-only and their credentials cannot modify the tailnet. This includes authorizing, tagging, or deleting devices, editing the ACL policy, DNS, or keys, or any other operation that changes tailnet state. If a task appears to require a Tailscale write, don't attempt it — stop and explain that you lack write access instead.
      ''
    ];
  };
}
