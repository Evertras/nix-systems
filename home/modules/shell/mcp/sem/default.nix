{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.evertras.home.shell.mcp.sem;
in
{
  options.evertras.home.shell.mcp.sem = {
    enable = mkEnableOption ''
      the sem semantic-diff MCP server.  Unlike the fleet servers, sem is not
      a networked container: it operates on the local repo (tree-sitter over
      the working tree and .git), so its single self-contained binary is baked
      into the claude-sandbox image and run as a stdio MCP server inside the
      sandbox, launched by claude against whatever repo is mounted at the
      workdir.  Loaded in every sandbox via `claude-sandbox.globalMcp`, so it
      needs no per-profile or per-repo wiring
    '';

    version = mkOption {
      type = types.str;
      default = "0.15.1";
      description = "sem release version baked into the claude-sandbox image.";
    };
  };

  config = mkIf cfg.enable {
    # A stdio MCP config claude launches inside the sandbox.  sem inherits the
    # sandbox's workdir, so one config serves every repo with no per-repo
    # wiring.  No url/network/credentials: it is a local, offline tool.
    evertras.home.shell.mcp.claude = {
      enable = true;
      files.sem.servers.sem = {
        command = "sem";
        args = [ "mcp" ];
      };
    };

    evertras.home.shell.claude-sandbox = {
      # Load sem in every sandbox, regardless of profile.
      globalMcp = [ config.evertras.home.shell.mcp.claude.paths.sem ];

      # Nudge the agent to actually reach for the entity-level tools instead of
      # reading whole files / diffing by line.
      extraInstructions = [
        ''
          When the sem MCP server is available, prefer its entity-level tools (sem_impact, sem_context, sem_diff, sem_entities, sem_blame, sem_log) to reason about which functions, classes, and methods changed and their blast radius, instead of reading whole files or diffing line by line.
        ''
      ];

      # Bake the pinned sem binary into the sandbox image, arch-aware, mirroring
      # how the github MCP server fetches its release binary.  It lands in
      # /usr/local/bin, already on the sandbox PATH.  SEM_NO_TELEMETRY and
      # SEM_LOCAL are baked in so sem never phones home and never needs to log
      # in: every command computes locally and makes no network calls.
      extraDockerfile = ''
        ENV SEM_NO_TELEMETRY=1 SEM_LOCAL=1
        RUN set -eu; \
            arch="$(uname -m)"; \
            case "$arch" in \
              x86_64 | amd64) a=x86_64 ;; \
              aarch64 | arm64) a=arm64 ;; \
              *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
            esac; \
            curl -fsSL "https://github.com/Ataraxy-Labs/sem/releases/download/v${cfg.version}/sem-linux-''${a}.tar.gz" \
              | tar -xz -C /usr/local/bin sem; \
            chmod +x /usr/local/bin/sem
      '';
    };
  };
}
