{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.evertras.home.shell.mcp;
  enabledServers = filterAttrs (_: s: s.enable) cfg.servers;

  # A single arg, double-quoted with the shell-special characters escaped.
  # Unlike escapeShellArg this never leaves a bare comma (which trips
  # shellcheck SC2054 inside an array literal) and never expands anything.
  dq = a: ''"${escape [ "\\" "\"" "$" "`" ] a}"'';

  # Emit the shell that brings one server up.  Credentials/config are produced
  # on the host by the server's `prepare` step, captured into a private
  # env-file, and handed to `docker run` via --env-file so they never appear
  # in argv or the process list.  The env-file is read at container creation
  # and deleted immediately after.
  mkServerUp =
    name: s:
    ''
      # ---- ${name} ----
    ''
    + optionalString (s.build != null) ''
      if ! docker image inspect ${escapeShellArg s.image} &>/dev/null; then
        echo "mcp-up: building image for ${name}..."
        docker build -t ${escapeShellArg s.image} - < ${pkgs.writeText "mcp-dockerfile-${name}" s.build}
      fi
    ''
    + ''
      env_file="$(mktemp)"
      chmod 600 "''${env_file}"
    ''
    + optionalString (s.prepare != null) ''
      # Run the prepare step in a subshell with `set -e` so a failure in any
      # line (not just the last) aborts before we launch with bad env.  Only
      # its stdout becomes env lines; diagnostics must go to stderr.
      if ! (
        set -e
      ${s.prepare}
      ) > "''${env_file}"; then
        echo "mcp-up: prepare step failed for ${name}" >&2
        exit 1
      fi
    ''
    + concatMapStrings (k: ''
      printf '%s\n' "${k}=${s.env.${k}}" >> "''${env_file}"
    '') (attrNames s.env)
    + ''
      run_args=(-d --rm --name ${escapeShellArg s.containerName} --network "''${network_name}" --env-file "''${env_file}")
    ''
    # Volumes are emitted raw inside double quotes so $HOME (etc.) expands at
    # runtime, matching the claude-sandbox convention.
    + concatMapStrings (v: ''
      run_args+=(-v "${v}")
    '') s.volumes
    + ''
      run_args+=(${escapeShellArg s.image})
    ''
    + concatMapStrings (a: ''
      run_args+=(${dq a})
    '') s.args
    + ''
      docker rm -f ${escapeShellArg s.containerName} &>/dev/null || true
      docker run "''${run_args[@]}"
      rm -f "''${env_file}"
      env_file=""
      echo "mcp-up: ${name} up as ${s.containerName} on ''${network_name}"
    '';
in
{
  options.evertras.home.shell.mcp = {
    network = mkOption {
      type = types.str;
      default = "mcp-net";
      description = ''
        User-defined docker network the MCP-server fleet shares.  `mcp-up`
        creates it if missing.  Point a claude-sandbox profile's `network`
        at the same name so claude can reach the servers by their container
        DNS names while staying isolated from the host.
      '';
    };

    servers = mkOption {
      default = { };
      description = ''
        Long-running MCP-server containers, keyed by name, all joined to
        `network`.  Bring the fleet up with `mcp-up` (a present-at-the-keyboard
        morning step, since `prepare` typically unlocks credentials via
        gpg/pass or 1Password), stop it with `mcp-down`, inspect with
        `mcp-status` / `mcp-logs <container>`.  Re-running `mcp-up` recreates
        the containers, which is how credentials are refreshed.
      '';
      example = literalExpression ''
        {
          my-k8s = {
            image = "my-k8s-mcp";
            build = '''
              FROM node:lts-slim
              RUN npm install -g kubernetes-mcp-server@latest
              ENTRYPOINT ["kubernetes-mcp-server"]
            ''';
            args = [ "--port" "8080" "--read-only" ];
            # One command; its stdout is captured verbatim as KEY=value lines.
            prepare = "aws-vault exec my-env -- aws configure export-credentials --format env-no-export";
            volumes = [ "$HOME/.kube/config:/kubeconfig:ro" ];
            env.KUBECONFIG = "/kubeconfig";
          };
        }
      '';
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Whether `mcp-up` should launch this server.";
              };

              image = mkOption {
                type = types.str;
                description = "Docker image to run.  Built from `build` if that is set, otherwise assumed to already exist / be pullable.";
              };

              build = mkOption {
                type = types.nullOr types.lines;
                default = null;
                description = ''
                  Dockerfile contents.  When set, `mcp-up` builds `image`
                  from it (via `docker build -t <image> -`) on first use.
                '';
              };

              containerName = mkOption {
                type = types.str;
                default = name;
                description = "Container name, which is also its DNS hostname on the network.  Defaults to the attribute name.";
              };

              args = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Arguments passed to the container's entrypoint (e.g. the server's `--port`/`--read-only` flags).";
              };

              prepare = mkOption {
                type = types.nullOr types.lines;
                default = null;
                description = ''
                  Host command(s) run once by `mcp-up` to produce this
                  server's environment.  Its stdout is captured verbatim into
                  a private env-file and passed to the container via
                  --env-file, so it must emit bare `KEY=value` lines (no
                  quotes, no `export `, single-line values) and send any
                  diagnostics to stderr.

                  This is where credentials come from, e.g.
                  `aws-vault exec <env> -- aws configure export-credentials
                  --format env-no-export`, or `pass show grafana/token | sed
                  's/^/GRAFANA_TOKEN=/'`.  It may also write side files (e.g.
                  a pinned kubeconfig) for `volumes` to mount.
                '';
              };

              env = mkOption {
                type = types.attrsOf types.str;
                default = { };
                description = ''
                  Extra static environment variables, appended to the env-file
                  after `prepare`.  Values are shell-expanded at `mcp-up` time,
                  so `$HOME` works.  Use for non-secret settings like
                  `KUBECONFIG`; put secrets in `prepare`.
                '';
              };

              volumes = mkOption {
                type = types.listOf types.str;
                default = [ ];
                example = [ "$HOME/.kube/config:/kubeconfig:ro" ];
                description = ''
                  `docker run -v` mount specs.  Expanded by the shell at
                  runtime, so `$HOME` works (a bare `~` does not).
                '';
              };
            };
          }
        )
      );
    };
  };

  config = mkIf (enabledServers != { }) {
    evertras.home.shell.funcs = {
      # Bring the whole fleet up.  Run this from a shell where `prepare` can
      # reach its credential sources (gpg-agent primed, 1Password signed in).
      mcp-up.body = ''
        network_name="${cfg.network}"

        if ! docker network inspect "''${network_name}" &>/dev/null; then
          echo "mcp-up: creating docker network ''${network_name}..."
          docker network create "''${network_name}" >/dev/null
        fi

        # Clean up the current server's env-file even if a launch fails.
        env_file=""
        trap 'rm -f "''${env_file:-}"' EXIT

        ${concatStringsSep "\n" (mapAttrsToList mkServerUp enabledServers)}
      '';

      mcp-down.body = ''
        ${concatMapStringsSep "\n" (s: ''
          if docker rm -f ${escapeShellArg s.containerName} &>/dev/null; then
            echo "mcp-down: stopped ${s.containerName}"
          fi
        '') (attrValues enabledServers)}
        echo "mcp-down: done"
      '';

      mcp-status.body = ''
        ${concatMapStringsSep "\n" (s: ''
          if docker ps --filter "name=^/${s.containerName}$" --format '{{.Names}}' | grep -q .; then
            docker ps --filter "name=^/${s.containerName}$" --format '  {{.Names}}: {{.Status}}'
          else
            echo "  ${s.containerName}: not running"
          fi
        '') (attrValues enabledServers)}
      '';

      mcp-logs.body = ''
        if [ "$#" -ne 1 ]; then
          echo "Usage: mcp-logs <container>" >&2
          exit 1
        fi
        docker logs -f "$1"
      '';
    };
  };
}
