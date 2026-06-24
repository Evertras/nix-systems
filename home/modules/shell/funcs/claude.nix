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
      lines = [
        "${name})"
      ]
      ++ map (d: "  dirs+=(\"${d}\")") profile.dirs
      ++ optional (profile.workdir != null) "  profile_workdir=\"${profile.workdir}\""
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
          workdir = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Host directory to start claude in; defaults to the first of `dirs`.";
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
        passthrough_args=()
        profile_workdir=""
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
          --workdir "''${sandbox_dir}" \
          "''${volume_mounts[@]}" \
          -v "/nix:/nix:ro" \
          -v "/nix/var/nix/daemon-socket/socket:/nix/var/nix/daemon-socket/socket" \
          -v "/etc/nix/nix.conf:/etc/nix/nix.conf:ro" \
          -v "''${HOME}/.claude:/home/user/.claude" \
          "''${claude_md_mount[@]}" \
          "''${claude_json_mount[@]}" \
          "''${image_name}" "''${passthrough_args[@]}"
      '';
    };
  };
}
