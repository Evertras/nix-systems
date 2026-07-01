{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.evertras.home.shell.mcp.claude;

  jsonFormat = pkgs.formats.json { };

  # Render one declared file to a `.mcp.json`-shaped store path.  Claude's
  # MCP config schema nests every server under a top-level `mcpServers`
  # object, so a single file can carry as many servers as we like.
  mkConfigFile =
    name: file: jsonFormat.generate "claude-mcp-${name}.json" { mcpServers = file.servers; };
in
{
  options.evertras.home.shell.mcp.claude = {
    enable = mkEnableOption "declarative Claude MCP config files";

    directory = mkOption {
      type = types.str;
      default = ".config/claude/mcp";
      description = ''
        Directory, relative to `$HOME`, where the generated MCP config
        files are written.  Files are written as `<name>.json` for each
        entry in `files`.

        These files are not loaded by claude automatically; pass their
        paths to claude with `--mcp-config` (or the claude-sandbox
        `mcp`/`-m` setting) to layer them on top of other servers.
      '';
    };

    files = mkOption {
      default = { };
      description = ''
        MCP config files to generate, keyed by file basename (the
        trailing `.json` is added automatically).  Each entry's `servers`
        becomes the `mcpServers` object of a Claude MCP config JSON, so a
        single file may declare any number of servers.

        This is handy for defining, say, one file per environment (a set
        of k8s MCP servers for staging, another for prod) and selectively
        loading whichever you need on top of your usual servers.
      '';
      example = literalExpression ''
        {
          k8s-staging.servers = {
            k8s = {
              command = "kubectl-mcp";
              args = [ "--context" "staging" ];
              env.KUBECONFIG = "$HOME/.kube/staging";
            };
          };
          k8s-prod.servers = {
            k8s = {
              command = "kubectl-mcp";
              args = [ "--context" "prod" ];
              env.KUBECONFIG = "$HOME/.kube/prod";
            };
          };
        }
      '';
      type = types.attrsOf (
        types.submodule {
          options = {
            servers = mkOption {
              # Freeform so every MCP server shape works: stdio
              # (command/args/env), http/sse (type/url/headers), and any
              # field claude adds later.  Keyed by server name.
              type = types.attrsOf (types.attrsOf types.anything);
              description = ''
                MCP servers for this file, keyed by server name.  Each
                value is the server definition exactly as it appears under
                `mcpServers` in a Claude MCP config, e.g.
                `{ command = "..."; args = [ ... ]; env = { ... }; }` for a
                stdio server, or `{ type = "http"; url = "..."; }` for an
                HTTP server.
              '';
            };
          };
        }
      );
    };

    paths = mkOption {
      type = types.attrsOf types.str;
      readOnly = true;
      default = mapAttrs (name: _: "$HOME/${cfg.directory}/${name}.json") cfg.files;
      defaultText = literalExpression ''mapAttrs (name: _: "$HOME/<directory>/<name>.json") files'';
      description = ''
        Read-only map from each file name to its runtime path (using
        `$HOME`, expanded by the shell).  Convenient for wiring generated
        files into the claude-sandbox `mcp` list, e.g.
        `mcp = builtins.attrValues config.evertras.home.shell.mcp.claude.paths;`.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.file = mapAttrs' (
      name: file: nameValuePair "${cfg.directory}/${name}.json" { source = mkConfigFile name file; }
    ) cfg.files;
  };
}
