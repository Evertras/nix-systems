{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.evertras.home.shell.mcp.github;

  # Fleet servers are named with an `mcp-` prefix (see the servers module) so
  # they're easy to spot in `docker ps`; the DNS name equals the container
  # name, so claude's URL uses the prefixed name too.  The nix key / claude
  # file name / `paths` entry stay unprefixed as `github`.
  fullName = "github";
  containerName = "mcp-${fullName}";

  # github-mcp-server's `http` mode is multi-tenant: it demands a per-request
  # `Authorization: Bearer` header and ignores GITHUB_PERSONAL_ACCESS_TOKEN.
  # That doesn't fit the fleet model, where a server holds its own credential
  # and claude connects over plain HTTP with no auth.  So instead we run the
  # server's *stdio* mode (which reads the token from the env) and bridge it to
  # streamable HTTP with supergateway.  The token therefore lives only inside
  # the container, exactly like the other fleet servers.
  stdioCmd =
    "github-mcp-server stdio --read-only"
    + optionalString (cfg.toolsets != [ ]) " --toolsets ${concatStringsSep "," cfg.toolsets}";
in
{
  options.evertras.home.shell.mcp.github = {
    enable = mkEnableOption "a read-only GitHub MCP server in the fleet";

    port = mkOption {
      type = types.port;
      default = 8090;
      description = ''
        Port the container listens on for streamable HTTP (path `/mcp`).
        Claude reaches it at `http://${containerName}:<port>/mcp` on the MCP
        network.  Pick one not used by another fleet server.
      '';
    };

    version = mkOption {
      type = types.str;
      default = "1.5.0";
      description = "github-mcp-server release version baked into the image.";
    };

    toolsets = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "repos"
        "issues"
        "pull_requests"
      ];
      description = ''
        Toolsets to enable (github-mcp-server `--toolsets`).  Empty uses the
        server's own default selection.  Read-only is always enforced
        regardless of which toolsets are enabled.
      '';
    };

    tokenCommand = mkOption {
      type = types.str;
      default = "gh auth token";
      description = ''
        Host command run by `mcp-up`; its stdout is the GitHub token.  Use a
        token with read-only scopes (e.g. a fine-grained PAT with read
        permissions).  The value lives only inside the container, passed via a
        private env-file as GITHUB_PERSONAL_ACCESS_TOKEN, and is never exposed
        to claude-sandbox, which reaches the server over plain HTTP by name.
      '';
    };
  };

  config = mkIf cfg.enable {
    evertras.home.shell.mcp = {
      # One long-running container in the fleet, bridging github-mcp-server's
      # read-only stdio server to streamable HTTP.
      servers.${fullName} = {
        inherit containerName;
        image = "evertras-github-mcp";
        build = ''
          FROM node:lts-slim
          RUN apt-get update \
              && apt-get install -y --no-install-recommends curl ca-certificates \
              && rm -rf /var/lib/apt/lists/* \
              && npm install -g supergateway
          RUN set -eu; \
              arch="$(uname -m)"; \
              case "$arch" in \
                x86_64) a=x86_64 ;; \
                aarch64 | arm64) a=arm64 ;; \
                *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
              esac; \
              curl -fsSL "https://github.com/github/github-mcp-server/releases/download/v${cfg.version}/github-mcp-server_Linux_''${a}.tar.gz" \
                | tar -xz -C /usr/local/bin github-mcp-server; \
              chmod +x /usr/local/bin/github-mcp-server
          ENTRYPOINT ["supergateway"]
        '';
        args = [
          "--stdio"
          stdioCmd
          "--outputTransport"
          "streamableHttp"
          "--streamableHttpPath"
          "/mcp"
          "--port"
          (toString cfg.port)
          "--host"
          "0.0.0.0"
        ];
        # Mint the token on the host; its stdout becomes the container's
        # GITHUB_PERSONAL_ACCESS_TOKEN via the private env-file.  `set -e` in
        # the prepare subshell means a failing tokenCommand aborts the launch.
        prepare = ''
          token="$(${cfg.tokenCommand})"
          printf 'GITHUB_PERSONAL_ACCESS_TOKEN=%s\n' "$token"
        '';
      };

      # Matching claude MCP config file, reached by container DNS name.  This
      # exposes `...mcp.claude.paths.github` for wiring into a claude-sandbox
      # profile's `mcp` list.
      claude = {
        enable = true;
        files.${fullName}.servers.${fullName} = {
          type = "http";
          url = "http://${containerName}:${toString cfg.port}/mcp";
        };
      };
    };
  };
}
