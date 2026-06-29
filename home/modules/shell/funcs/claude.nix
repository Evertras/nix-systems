{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.evertras.home.shell.claude-sandbox;

  dockerfileSrc = pkgs.writeText "claude-sandbox-dockerfile" ''
    FROM node:lts-slim

    RUN apt-get update && apt-get install -y \
        git \
        ca-certificates \
        curl \
        python3 \
        python3-pip \
        python3-venv \
        && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
        && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
        && apt-get update && apt-get install -y gh \
        && rm -rf /var/lib/apt/lists/*

    ENV PATH="/root/.local/bin:${"$"}{PATH}"

    RUN curl -fsSL https://claude.ai/install.sh | bash

    RUN chmod a+rx /root /root/.local /root/.local/bin \
        && mkdir -p /home/user/.local/bin \
        && ln -s /root/.local/bin/claude /home/user/.local/bin/claude

    RUN git config --global --add safe.directory '*'

    RUN mkdir -p /home/user && chmod 777 /home/user

    WORKDIR /sandbox

    # Default sandbox-wide instructions.  A profile may override this by
    # mounting its own CLAUDE.md over /sandbox/CLAUDE.md at runtime.
    COPY <<EOF /sandbox/CLAUDE.md
    If a flake.nix file exists in the working directory, use nix develop to enter the development environment before running project commands (build, test, lint, etc). This ensures the correct toolchain and dependencies are available.
    EOF

    ENTRYPOINT ["claude"]
  '';

  # Resolve a profile's CLAUDE.md to a store path, or null if it has none.
  # instructionsFile wins over inline instructions when both are set.
  mkInstrPath =
    name: profile:
    if profile.instructionsFile != null then
      profile.instructionsFile
    else if profile.instructions != null then
      pkgs.writeText "claude-sandbox-claude-md-${name}" profile.instructions
    else
      null;

  # Build a bash `case` branch for one profile.  Indentation inside a case
  # branch is cosmetic, so we keep it simple.
  mkBranch =
    name: profile:
    let
      instr = mkInstrPath name profile;
      # Each env var is either imported from the host (command == null) or
      # produced by running its command on the host at launch time.  The
      # latter go into parallel key/command arrays so the value is only
      # materialized at runtime, never baked into the store.
      envLines = concatLists (
        mapAttrsToList (
          key: e:
          if e.command != null then
            [
              "  env_cmd_keys+=(\"${key}\")"
              "  env_cmd_vals+=(${escapeShellArg e.command})"
            ]
          else
            [ "  extra_env_keys+=(\"${key}\")" ]
        ) profile.env
      );
      lines = [
        "${name})"
      ]
      ++ map (d: "  dirs+=(\"${d}\")") profile.dirs
      ++ envLines
      ++ map (m: "  mcp_configs+=(\"${m}\")") profile.mcp
      ++ optional (profile.workdir != null) "  profile_workdir=\"${profile.workdir}\""
      ++ optional (profile.network != null) "  profile_network=\"${profile.network}\""
      ++ optional (instr != null) "  profile_claude_md=\"${instr}\""
      ++ [ "  ;;" ];
    in
    concatStringsSep "\n    " lines;

  profileCases = concatStringsSep "\n    " (mapAttrsToList mkBranch cfg.profiles);

  hasProfiles = cfg.profiles != { };

  # Only declare the single-select guard variable when profiles exist,
  # otherwise it would be an unused variable (shellcheck SC2034).
  profileSelectedDecl = optionalString hasProfiles ''profile_selected=""'';

  # The `-p` arg handler.  With no profiles defined every inner branch would
  # exit, making `shift 2` unreachable (SC2317), so emit a plain error then.
  profileFlagCase =
    if hasProfiles then
      ''
        -p)
                  # Load a named profile's dirs/workdir/instructions.  Only one
                  # profile may be selected; combining them makes no sense.
                  if [[ -n "''${profile_selected}" ]]; then
                    echo "claude-sandbox: only one profile may be selected" >&2
                    exit 1
                  fi
                  profile_selected=1
                  case "''${2}" in
                    ${profileCases}
                    *)
                      echo "claude-sandbox: unknown profile: ''${2}" >&2
                      exit 1
                      ;;
                  esac
                  shift 2
                  ;;''
    else
      ''
        -p)
                  echo "claude-sandbox: no profiles are defined" >&2
                  exit 1
                  ;;'';
in
{
  options.evertras.home.shell.claude-sandbox.profiles = mkOption {
    default = { };
    description = ''
      Named claude-sandbox profiles, selected with `claude-sandbox -p <name>`.

      Each profile preloads a set of mounted directories, an optional
      working directory, and optional CLAUDE.md instructions.  Extra `-d`
      flags passed on the command line are appended to the profile's dirs,
      and any remaining args are passed through to claude.

      Directory strings are expanded by the shell at runtime, so `$HOME`
      works (but a bare `~` does not, since it is quoted).
    '';
    example = literalExpression ''
      {
        tdb = {
          dirs = [ "$HOME/dev/tdb" "$HOME/dev/tdb-docs" ];
          workdir = "$HOME/dev/tdb";
          env = {
            # Import the value from the calling environment.
            AWS_PROFILE = { };
            # Load the value on demand by running a command on the host.
            GITHUB_TOKEN.command = "pass show github/token";
            TF_API_TOKEN.command = "terraform -chdir=$HOME/dev/tdb/infra output -raw api_token";
          };
          mcp = [ "$HOME/dev/tdb/.mcp.json" ];
          instructions = '''
            Always run tests with `make test`.
            Use conventional commit messages.
          ''';
        };
      }
    '';
    type = types.attrsOf (
      types.submodule {
        options = {
          dirs = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Host directories to mount into the sandbox.";
          };
          env = mkOption {
            default = { };
            description = ''
              Environment variables to expose inside the sandbox, keyed by
              variable name.

              For each entry, if `command` is null (the default) the value is
              imported from the calling environment, exactly like passing `-e
              <KEY>` to `docker run`.  If `command` is set, that command is run
              on the host at launch time and its (trimmed) stdout becomes the
              value.  This lets sensitive credentials be pulled from a secret
              store or other tooling on demand instead of living in the
              environment, e.g. `pass show ...` or `terraform output -raw ...`.

              Use an empty attrset, `BAR = { };`, to import `BAR` from the
              host environment.

              Command-loaded values are passed to the container via a private
              `--env-file` so they never appear in `docker inspect`, the
              process list, or the nix store.  Commands run through the shell,
              so pipes and `$HOME` work.

              Extra `-e` flags on the command line are added as host-imported
              vars.
            '';
            type = types.attrsOf (
              types.submodule {
                options = {
                  command = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = ''
                      Shell command run on the host to produce this variable's
                      value.  When null, the value is imported from the calling
                      environment instead.
                    '';
                  };
                };
              }
            );
          };
          mcp = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = ''
              Paths to MCP server config JSON files on the host.  Each file
              is mounted read-only into the sandbox and passed to claude via
              `--mcp-config`.  Extra `-m` flags on the command line are added
              to these.

              Path strings are expanded by the shell at runtime, so `$HOME`
              works (but a bare `~` does not, since it is quoted).
            '';
          };
          workdir = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Host directory to start claude in; defaults to the first of `dirs`.";
          };
          network = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "host";
            description = ''
              Docker network mode for the sandbox, passed straight through to
              `docker run --network`.  When null (the default) docker's normal
              bridge network is used, which keeps the sandbox in its own
              network namespace.

              Setting this to `host` shares the host's entire network stack
              with the sandbox: it can reach every service bound to the host's
              localhost, bind host ports, and follow host routes such as a VPN
              tunnel.  This removes the network isolation the sandbox otherwise
              provides, so only use it when you specifically need it.

              A `--network` flag on the command line overrides this.
            '';
          };
          instructions = mkOption {
            type = types.nullOr types.lines;
            default = null;
            description = ''
              Inline CLAUDE.md contents for this profile, mounted over
              /sandbox/CLAUDE.md.  Ignored if `instructionsFile` is set.
            '';
          };
          instructionsFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Path to a CLAUDE.md file for this profile, mounted over /sandbox/CLAUDE.md.";
          };
        };
      }
    );
  };

  config.evertras.home.shell.funcs = {
    claude-sandbox = {
      body = ''
        image_name="evertras-claude-sandbox"

        need_build=false
        build_flags=()
        dirs=()
        extra_env_keys=()
        env_cmd_keys=()
        env_cmd_vals=()
        mcp_configs=()
        passthrough_args=()
        profile_workdir=""
        profile_network=""
        cli_network=""
        profile_claude_md=""
        ${profileSelectedDecl}

        while [[ $# -gt 0 ]]; do
          case "''${1}" in
            ${profileFlagCase}
            --rebuild)
              docker rmi "''${image_name}" 2>/dev/null || true
              need_build=true
              shift
              ;;
            --update)
              # Like --rebuild but bypasses the layer cache and re-pulls the
              # base image, so the apt packages and the claude install.sh step
              # actually re-run and pick up new versions.
              docker rmi "''${image_name}" 2>/dev/null || true
              need_build=true
              build_flags=(--no-cache --pull)
              shift
              ;;
            -d)
              dirs+=("$(realpath "''${2}")")
              shift 2
              ;;
            -e)
              # Import an env var key from the host; docker resolves the value.
              extra_env_keys+=("''${2}")
              shift 2
              ;;
            -m)
              # Mount an MCP server config file and pass it to claude.
              mcp_configs+=("''${2}")
              shift 2
              ;;
            --network)
              # Override docker's network mode (e.g. `host` to follow a VPN
              # tunnel).  Takes precedence over a profile's `network` setting.
              cli_network="''${2}"
              shift 2
              ;;
            *)
              passthrough_args+=("''${1}")
              shift
              ;;
          esac
        done

        if ! docker image inspect "''${image_name}" &>/dev/null; then
          need_build=true
        fi

        if "''${need_build}"; then
          echo "Building Claude sandbox image..."
          docker build "''${build_flags[@]}" -t "''${image_name}" - < ${dockerfileSrc}
        fi

        claude_json="''${HOME}/.claude.json"
        claude_json_mount=()
        if [ -f "''${claude_json}" ]; then
          claude_json_mount=(-v "''${claude_json}:/home/user/.claude.json")
        fi

        # If no dirs given (neither profile nor -d), default to current directory
        if [ "''${#dirs[@]}" -eq 0 ]; then
          dirs=("$(pwd)")
        fi

        # Normalize every dir to an absolute path and mount it at the same
        # path under /sandbox so paths line up inside and outside the box.
        volume_mounts=()
        resolved_dirs=()
        for dir in "''${dirs[@]}"; do
          rp="$(realpath "''${dir}")"
          resolved_dirs+=("''${rp}")
          volume_mounts+=(-v "''${rp}:/sandbox''${rp}")
        done

        if [ -n "''${profile_workdir}" ]; then
          sandbox_dir="/sandbox$(realpath "''${profile_workdir}")"
        else
          sandbox_dir="/sandbox''${resolved_dirs[0]}"
        fi

        # A profile may supply its own CLAUDE.md, mounted over the baked default.
        claude_md_mount=()
        if [ -n "''${profile_claude_md}" ]; then
          claude_md_mount=(-v "''${profile_claude_md}:/sandbox/CLAUDE.md:ro")
        fi

        # Pass through requested env var keys (from profiles and -e flags);
        # `-e KEY` with no value tells docker to take it from this environment.
        env_flags=()
        for env_key in "''${extra_env_keys[@]}"; do
          env_flags+=(-e "''${env_key}")
        done

        # Command-loaded env vars: run each command on the host now and stash
        # the resulting KEY=value lines in a private env-file for docker to
        # read.  Using --env-file keeps the secret out of argv, the process
        # list, and `docker inspect`.
        env_file_flags=()
        if [ "''${#env_cmd_keys[@]}" -gt 0 ]; then
          env_file="$(mktemp)"
          chmod 600 "''${env_file}"
          trap 'rm -f "''${env_file}"' EXIT
          for i in "''${!env_cmd_keys[@]}"; do
            env_key="''${env_cmd_keys[$i]}"
            env_cmd="''${env_cmd_vals[$i]}"
            if ! env_val="$(eval "''${env_cmd}")"; then
              echo "claude-sandbox: failed to load env var ''${env_key} via: ''${env_cmd}" >&2
              exit 1
            fi
            printf '%s=%s\n' "''${env_key}" "''${env_val}" >> "''${env_file}"
          done
          env_file_flags=(--env-file "''${env_file}")
        fi

        # Mount each MCP config (read-only) at its host path under /sandbox and
        # tell claude to load it with --mcp-config.
        mcp_mounts=()
        mcp_args=()
        for mcp_config in "''${mcp_configs[@]}"; do
          rp="$(realpath "''${mcp_config}")"
          mcp_mounts+=(-v "''${rp}:/sandbox''${rp}:ro")
          mcp_args+=(--mcp-config "/sandbox''${rp}")
        done

        # Resolve the network mode: a `--network` flag wins over the profile's
        # `network`, which wins over docker's default bridge (no flag).
        network_flags=()
        network_mode="''${cli_network:-''${profile_network}}"
        if [ -n "''${network_mode}" ]; then
          network_flags=(--network "''${network_mode}")
        fi

        nix_bin_dir="$(dirname "$(readlink -f "$(which nix)")")"

        # --user is required so that files created/modified in the volume mount
        # are owned by the calling user rather than root.
        # HOME must point to a world-writable path since the container user is
        # a dynamic UID with no real home directory.
        docker run --rm -it \
          --user "$(id -u):$(id -g)" \
          -e HOME=/home/user \
          -e TERM="''${TERM}" \
          -e DISABLE_AUTOUPDATER=1 \
          -e NIX_REMOTE=daemon \
          -e PATH="''${nix_bin_dir}:/root/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
          "''${network_flags[@]}" \
          "''${env_flags[@]}" \
          "''${env_file_flags[@]}" \
          --workdir "''${sandbox_dir}" \
          "''${volume_mounts[@]}" \
          "''${mcp_mounts[@]}" \
          -v "/nix:/nix:ro" \
          -v "/nix/var/nix/daemon-socket/socket:/nix/var/nix/daemon-socket/socket" \
          -v "/etc/nix/nix.conf:/etc/nix/nix.conf:ro" \
          -v "/etc/resolv.conf:/etc/resolv.conf:ro" \
          -v "''${HOME}/.claude:/home/user/.claude" \
          "''${claude_md_mount[@]}" \
          "''${claude_json_mount[@]}" \
          "''${image_name}" "''${mcp_args[@]}" "''${passthrough_args[@]}"
      '';
    };
  };
}
