# Shared launcher generator behind claude-sandbox and codex-sandbox.
#
# Not a module: claude.nix and codex.nix call it as a function, so both
# launchers are built from the same `claude-sandbox` options - the same
# profiles, mounted dirs, scratch spaces, docker modes, env, networks, MCP
# configs, and instructions - and differ only in the agent baked into the
# image and how that agent is handed its config.
#
# An agent is an attrset of:
#
#   name           launcher name, also the prefix for its errors and dind names
#   label          human name for the "Building ... sandbox image" message
#   image          docker image name
#   dockerfile     Dockerfile lines appended after the shared base image and
#                  `extraDockerfile`: installs the agent and sets ENTRYPOINT
#   prepare        bash run at launch that fills the `agent_mounts`,
#                  `agent_env`, and `agent_args` arrays from `mcp_configs` (host
#                  paths), `profile_instructions` (a host file, or empty when
#                  the profile adds nothing of its own), and `yolo` (true/false)
#   runtimeInputs  extra packages for the launcher's PATH (optional)
{
  lib,
  pkgs,
  cfg,
}:
with lib;
let
  # Instructions applied to EVERY sandbox, whichever agent runs in it, and
  # prepended to any profile's own instructions so sandbox-wide guidance
  # always applies.  Put shared guidance here rather than duplicating it into
  # individual profiles.
  baseInstructions = ''
    If a flake.nix file exists in the working directory, use nix develop to enter the development environment before running project commands (build, test, lint, etc). This ensures the correct toolchain and dependencies are available.

    When a GitHub MCP server is available, use it for GitHub operations (issues, pull requests, repositories, code search, etc.) instead of the `gh` CLI.

    You do not have credentials to write to GitHub, so writes will fail. This includes pushing commits or branches, opening or editing pull requests, creating or commenting on issues, editing releases, or any other operation that modifies remote GitHub state. Read-only GitHub operations work fine. If a task appears to require writing to GitHub, don't attempt it — stop and explain that you lack write access instead.'';

  # The baked instructions plus any `extraInstructions` contributed by other
  # modules (e.g. the sem MCP module), joined as separate paragraphs.
  globalInstructions = concatStringsSep "\n\n" (
    [ baseInstructions ] ++ map (s: removeSuffix "\n" s) cfg.extraInstructions
  );

  globalInstructionsFile = pkgs.writeText "sandbox-global-instructions" (globalInstructions + "\n");

  # Where a profile's scratch directory lives, by convention
  # `<scratchBase>/<profile>-scratch`.  The `-scratch` suffix is the point:
  # the bare profile name collides with the repo it's named after (the
  # `tile-ai` profile's main repo is also `tile-ai`), and the basename is what
  # actually gets read in isolation - in grep output, in `cd`, in the agent's
  # own prose.  Carrying the meaning in the leaf makes that unambiguous
  # wherever it surfaces.
  scratchPathOf = name: "${cfg.scratchBase}/${name}-scratch";

  # The CLAUDE.md section describing a profile's scratch directory, generated
  # rather than written per-profile so every scratch space is explained the
  # same way - including what does *not* belong in it.
  mkScratchInstructions =
    name:
    let
      leaf = "${name}-scratch";
      path = "/sandbox${scratchPathOf name}";
    in
    ''
      # Scratch Directory

      `${path}/` is this sandbox's persistent scratch directory, mounted read-write.  Use it for work that should outlive a single session but belongs in no repository: investigation notes, plans, throwaway scripts, query output, sample data, and intermediate results.

      It is a git repository with no remote.  Commit anything worth finding again, so `git log` and `git diff` can answer "what was tried last time"; nothing here is ever pushed anywhere.

      `${leaf}` is a scratch directory, not a clone - do not confuse it with a similarly named repository mounted elsewhere in this sandbox.

      Code, tests, docs, and configuration belong in their own repository, not here.  In particular, do not use this directory to stash edits you could not make in a repo, or to keep an editable copy of a read-only mount.  If a task needs a change somewhere you cannot write, say so instead.

      This is not the ephemeral per-session scratchpad under `/tmp` that the harness may also point you at.  That one is thrown away when the session ends; this one persists.  When in doubt about whether something will matter tomorrow, put it here.
    '';

  # Normalize the `docker` option to a mode string.  `true` and `false` are
  # the option's original spelling, still accepted so existing profiles keep
  # working: `true` meant the host's socket, and that is what it still means.
  dockerModeOf =
    profile:
    if profile.docker == true then
      "host"
    else if profile.docker == false then
      "none"
    else
      profile.docker;

  # The CLAUDE.md section describing docker access, generated per mode.  What
  # actually trips an agent up differs between them.  With `host` it is that
  # the containers it starts are siblings on the host rather than children of
  # this sandbox, and that mount paths are resolved by the host daemon, so the
  # `/sandbox` prefix must be dropped.  With `dind` it is the opposite: the
  # paths line up, but none of the host's images or containers are there.
  dockerInstructionsHost = ''
    # Host Docker

    `docker` here talks to the host's docker daemon over a bind-mounted socket; there is no daemon inside the sandbox.  Containers you start are siblings of this sandbox running directly on the host, they share the host's docker state with everything else on it, and they outlive this session unless you remove them.

    Paths do not carry over.  `-v`, `--mount`, and `--build-context` arguments are resolved by the host daemon against the host filesystem, so pass the host path (`/home/...`) rather than the `/sandbox`-prefixed path you see here.  A `/sandbox/...` path will not fail loudly - docker will happily create an empty directory on the host and mount that instead.

    Name what you create so it can be found again, and clean up containers, images, and volumes you no longer need.
  '';

  dockerInstructionsDind = ''
    # Sandboxed Docker

    `docker` here talks to a docker-in-docker daemon started alongside this sandbox, not to the host's daemon.  It has its own images, containers, volumes, and networks: the host's containers are neither visible nor reachable from here, and nothing you do affects them.

    The image cache starts empty the first time a profile uses it, so early pulls are slow; it persists between sessions, so later ones are not.  Registry credentials are not carried over, so a private pull needs a `docker login` here first.

    This sandbox's mounted directories are mounted into that daemon at the same paths, so `-v /sandbox/...:/...` works with the paths you actually see.  Anything outside them does not exist to the daemon, and a path it cannot resolve is silently created as an empty directory rather than failing.

    Containers you start are children of that daemon and go away when this session ends.  Images and named volumes survive.
  '';

  dockerInstructionsOf =
    mode: if mode == "host" then dockerInstructionsHost else dockerInstructionsDind;

  # Everything both agents' images share.  Module-contributed
  # `extraDockerfile` lines (e.g. the sem binary) and then each agent's own
  # install step are appended to this.
  dockerfileBase = ''
    # Debian 13 "trixie" (glibc >=2.39), not the default bookworm-based
    # node:lts-slim (glibc 2.36): the sem MCP binary is built against
    # GLIBC_2.39 and fails to start on the older base.
    FROM node:lts-trixie-slim

    RUN apt-get update && apt-get install -y \
        git \
        ca-certificates \
        curl \
        jq \
        python3 \
        python3-pip \
        python3-venv \
        && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
        && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
        && apt-get update && apt-get install -y gh \
        && rm -rf /var/lib/apt/lists/*

    # yq (mikefarah's Go binary, not Debian's python jq-wrapper of the same
    # name): a single arch-aware binary dropped in /usr/local/bin, matching the
    # `yq <path-expr>` syntax used in the repos' shell functions.
    RUN set -eu; \
        arch="$(dpkg --print-architecture)"; \
        curl -fsSL "https://github.com/mikefarah/yq/releases/download/v4.53.3/yq_linux_''${arch}" \
          -o /usr/local/bin/yq; \
        chmod +x /usr/local/bin/yq

    RUN git config --global --add safe.directory '*'

    RUN mkdir -p /home/user && chmod 777 /home/user

    # Debian's /etc/profile overwrites PATH outright, so any login shell -
    # which is how codex runs every command - would lose the host's nix bin
    # dir the launcher puts on it.  The launcher passes the intended PATH as
    # SANDBOX_PATH too, and this restores it at the end of /etc/profile.
    RUN printf '%s\n' 'if [ -n "''${SANDBOX_PATH:-}" ]; then PATH="''${SANDBOX_PATH}"; export PATH; fi' \
        > /etc/profile.d/sandbox-path.sh

    WORKDIR /sandbox

    ${cfg.extraDockerfile}
  '';

  dockerfileOf =
    agent: pkgs.writeText "${agent.name}-dockerfile" (dockerfileBase + "\n" + agent.dockerfile);

  # Resolve a profile's instructions (CLAUDE.md for claude, developer
  # instructions for codex) to a store path, or null if it has nothing of its
  # own to say (in which case the global instructions alone apply).  The
  # global instructions are always prepended so sandbox-wide guidance applies,
  # and a profile with a scratch directory gets the generated scratch section
  # appended last, as an addendum after its own prose.
  # instructionsFile wins over inline instructions when both are set.
  mkInstrPath =
    name: profile:
    let
      profileFile =
        if profile.instructionsFile != null then
          profile.instructionsFile
        else if profile.instructions != null then
          pkgs.writeText "sandbox-instructions-${name}-profile" profile.instructions
        else
          null;

      scratchFile =
        if profile.scratch then
          pkgs.writeText "sandbox-instructions-${name}-scratch" (mkScratchInstructions name)
        else
          null;

      dockerFile =
        let
          dockerMode = dockerModeOf profile;
        in
        if dockerMode != "none" then
          pkgs.writeText "sandbox-instructions-${name}-docker" (dockerInstructionsOf dockerMode)
        else
          null;

      parts = [
        globalInstructionsFile
      ]
      ++ filter (p: p != null) [
        profileFile
        scratchFile
        dockerFile
      ];

      # Joined with a blank line between each part, so the sections stay
      # separate paragraphs regardless of how each file ends.
      catLines = concatStringsSep "\n  printf '\\n'\n" (map (p: "  cat ${p}") parts);
    in
    if profileFile == null && scratchFile == null && dockerFile == null then
      null
    else
      pkgs.runCommand "sandbox-instructions-${name}" { } ''
        {
        ${catLines}
        } > "$out"
      '';

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
      ++ map (d: "  dirs_ro+=(\"${d}\")") profile.dirsRo
      ++ optional profile.scratch "  scratch_dirs+=(\"${scratchPathOf name}\")"
      ++ optional (dockerModeOf profile != "none") "  docker_mode=\"${dockerModeOf profile}\""
      ++ envLines
      ++ map (m: "  mcp_configs+=(\"${m}\")") profile.mcp
      ++ optional (profile.workdir != null) "  profile_workdir=\"${profile.workdir}\""
      ++ optional (profile.network != null) "  profile_network=\"${profile.network}\""
      ++ optional (instr != null) "  profile_instructions=\"${instr}\""
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
    agent:
    if hasProfiles then
      ''
        -p)
                  # Load a named profile's dirs/workdir/instructions.  Only one
                  # profile may be selected; combining them makes no sense.
                  if [[ -n "''${profile_selected}" ]]; then
                    echo "${agent.name}: only one profile may be selected" >&2
                    exit 1
                  fi
                  profile_selected=1
                  profile_name="''${2}"
                  case "''${2}" in
                    ${profileCases}
                    *)
                      echo "${agent.name}: unknown profile: ''${2}" >&2
                      exit 1
                      ;;
                  esac
                  shift 2
                  ;;''
    else
      ''
        -p)
                  echo "${agent.name}: no profiles are defined" >&2
                  exit 1
                  ;;'';

  # The `-l` arg handler: list the available profiles, one per line.
  # attrNames is already sorted alphabetically, so the baked list is too.
  profileListFlagCase =
    agent:
    if hasProfiles then
      ''
        -l)
                  printf '%s\n' ${concatMapStringsSep " " escapeShellArg (attrNames cfg.profiles)}
                  exit 0
                  ;;''
    else
      ''
        -l)
                  echo "${agent.name}: no profiles are defined" >&2
                  exit 1
                  ;;'';

  # Bash array literal of the always-loaded MCP configs, each double-quoted so
  # `$HOME` (etc.) expands at runtime.  Empty when none are declared.
  globalMcpArray = concatMapStringsSep " " (m: ''"${m}"'') cfg.globalMcp;
in
{
  inherit globalInstructions globalInstructionsFile;

  # The `funcs` entry for one agent's launcher.
  mkSandboxFunc = agent: {
    # git is needed to initialize a profile's scratch directory on first
    # launch; everything else (docker, realpath) comes from the host PATH.
    runtimeInputs = [ pkgs.git ] ++ (agent.runtimeInputs or [ ]);

    body = ''
      image_name="${agent.image}"

      need_build=false
      build_flags=()
      dirs=()
      dirs_ro=()
      scratch_dirs=()
      extra_env_keys=()
      env_cmd_keys=()
      env_cmd_vals=()
      # Seed with the always-loaded global configs; profile and `-m` configs
      # are appended after, so globals load first.
      mcp_configs=(${globalMcpArray})
      passthrough_args=()
      profile_workdir=""
      profile_network=""
      cli_network=""
      profile_instructions=""
      docker_mode="none"
      profile_name="default"
      yolo=false
      ${profileSelectedDecl}

      # One EXIT trap for everything needing teardown: bash replaces a trap
      # rather than stacking it, so a second `trap ... EXIT` further down
      # would silently drop the env-file cleanup and leave a secret on disk.
      env_file=""
      dind_name=""
      dind_network=""
      cleanup() {
        if [ -n "''${env_file}" ]; then
          rm -f "''${env_file}"
        fi
        if [ -n "''${dind_name}" ]; then
          docker rm -f "''${dind_name}" >/dev/null 2>&1 || true
        fi
        if [ -n "''${dind_network}" ]; then
          docker network rm "''${dind_network}" >/dev/null 2>&1 || true
        fi
      }
      trap cleanup EXIT

      while [[ $# -gt 0 ]]; do
        case "''${1}" in
          ${profileFlagCase agent}
          ${profileListFlagCase agent}
          --rebuild)
            docker rmi "''${image_name}" 2>/dev/null || true
            need_build=true
            shift
            ;;
          --update)
            # Like --rebuild but bypasses the layer cache and re-pulls the
            # base image, so the apt packages and the agent install step
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
            # Load an extra MCP server config file.
            mcp_configs+=("''${2}")
            shift 2
            ;;
          --network)
            # Override docker's network mode (e.g. `host` to follow a VPN
            # tunnel).  Takes precedence over a profile's `network` setting.
            cli_network="''${2}"
            shift 2
            ;;
          --docker)
            # Bare --docker gets the contained daemon.  Handing over the
            # host's socket is an escape hatch out of the sandbox as much as
            # a feature - it is a root API, so anything in here can run a
            # privileged container mounting the host's filesystem - so that
            # one has to be asked for by name.
            #
            # The mode is optional, so the next arg is only swallowed when it
            # actually is one.  Every other value-taking flag here spells its
            # value with a space, so `--docker dind` is the natural thing to
            # type; anything else stays a passthrough arg, which keeps
            # `--docker --yolo` and `--docker "some prompt"` working.  A
            # mistyped mode therefore lands in the prompt rather than being
            # caught, so `--docker=<mode>` is the form that always validates.
            docker_mode="dind"
            case "''${2:-}" in
              none | host | dind)
                docker_mode="''${2}"
                shift
                ;;
            esac
            shift
            ;;
          --docker=*)
            docker_mode="''${1#--docker=}"
            case "''${docker_mode}" in
              none | host | dind) ;;
              *)
                echo "${agent.name}: unknown docker mode: ''${docker_mode} (expected none, host, or dind)" >&2
                exit 1
                ;;
            esac
            shift
            ;;
          --yolo)
            # Run the agent with every permission prompt skipped.  This is
            # only safe because the sandbox already isolates it to the mounted
            # dirs and its own network namespace; the container is the blast
            # radius, not the host.
            yolo=true
            shift
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
        echo "Building ${agent.label} sandbox image..."
        docker build "''${build_flags[@]}" -t "''${image_name}" - < ${dockerfileOf agent}
      fi

      # A profile's scratch directory is created and git-initialized on
      # demand, so it exists from the first launch with no manual setup.
      # There is no remote and never will be; the repo is just history for
      # throwaway work.  Appended to dirs last, after any -d flags, so the
      # fallback workdir (resolved_dirs[0]) stays a real repo.
      for scratch_dir in "''${scratch_dirs[@]}"; do
        if [ ! -d "''${scratch_dir}" ]; then
          echo "Creating scratch directory ''${scratch_dir}"
          mkdir -p "''${scratch_dir}"
        fi
        if [ ! -e "''${scratch_dir}/.git" ]; then
          git init -q -b main "''${scratch_dir}"
        fi
        dirs+=("''${scratch_dir}")
      done

      # If no dirs given at all (neither profile nor -d), default to the
      # current directory.  A profile with only read-only dirs counts as
      # having dirs, so we don't silently mount the cwd read-write alongside.
      if [ "''${#dirs[@]}" -eq 0 ] && [ "''${#dirs_ro[@]}" -eq 0 ]; then
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

      # Read-only dirs mount the same way but with :ro, so the agent can read
      # and copy from them while the kernel refuses any write.  Appended after
      # the read-write dirs so resolved_dirs[0] (the fallback workdir) stays a
      # writable one whenever the profile has any.
      for dir in "''${dirs_ro[@]}"; do
        rp="$(realpath "''${dir}")"
        resolved_dirs+=("''${rp}")
        volume_mounts+=(-v "''${rp}:/sandbox''${rp}:ro")
      done

      # Hide secret-bearing files at the top of every mounted dir by binding
      # /dev/null over them, so the agent sees an empty file instead of the
      # contents (see `maskFiles`).  Added to volume_mounts so a dind sidecar,
      # which repeats these mounts, is masked the same way.
      mask_files=(${concatMapStringsSep " " escapeShellArg cfg.maskFiles})
      for rp in "''${resolved_dirs[@]}"; do
        for mask_file in "''${mask_files[@]}"; do
          if [ -f "''${rp}/''${mask_file}" ]; then
            volume_mounts+=(-v "/dev/null:/sandbox''${rp}/''${mask_file}:ro")
          fi
        done
      done

      if [ -n "''${profile_workdir}" ]; then
        sandbox_dir="/sandbox$(realpath "''${profile_workdir}")"
      else
        sandbox_dir="/sandbox''${resolved_dirs[0]}"
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
        for i in "''${!env_cmd_keys[@]}"; do
          env_key="''${env_cmd_keys[$i]}"
          env_cmd="''${env_cmd_vals[$i]}"
          if ! env_val="$(eval "''${env_cmd}")"; then
            echo "${agent.name}: failed to load env var ''${env_key} via: ''${env_cmd}" >&2
            exit 1
          fi
          printf '%s=%s\n' "''${env_key}" "''${env_val}" >> "''${env_file}"
        done
        env_file_flags=(--env-file "''${env_file}")
      fi

      # Resolve the network mode: a `--network` flag wins over the profile's
      # `network`, which wins over docker's default bridge (no flag).
      network_flags=()
      network_mode="''${cli_network:-''${profile_network}}"
      if [ -n "''${network_mode}" ]; then
        network_flags=(--network "''${network_mode}")
      fi

      # By default we bind the host's resolv.conf so the sandbox inherits the
      # host's DNS (e.g. a VPN's resolvers).  On a user-defined docker network
      # that would break things: name resolution there goes through docker's
      # embedded DNS (127.0.0.11), which resolves other containers by name and
      # forwards external lookups.  Overriding resolv.conf hides it, so a
      # profile pointing at another container by name (e.g. an MCP server)
      # can't resolve it.  So skip the override for user-defined networks
      # (anything other than the default bridge or host).
      resolv_mount=(-v "/etc/resolv.conf:/etc/resolv.conf:ro")
      if [ -n "''${network_mode}" ] && [ "''${network_mode}" != "host" ]; then
        resolv_mount=()
      fi

      # Agent-specific wiring: its config/auth mounts, environment, and
      # arguments, built from the resolved MCP configs, the profile's
      # instructions, and the yolo flag.
      agent_mounts=()
      agent_env=()
      agent_args=()
      ${agent.prepare}

      # Docker access.
      #
      # `host` binds the daemon's socket in and gives the sandbox the host's
      # own docker binary to drive it with, rather than baking a second copy
      # of the CLI into the image.  On NixOS that binary is a store path
      # whose dependencies resolve through the read-only /nix mount below, so
      # the single file is all that needs mounting.
      #
      # `dind` instead starts a private daemon in a sidecar container and
      # points DOCKER_HOST at it, leaving the host's docker state unreachable
      # from in here.  The same host binary drives it; only the endpoint
      # differs.
      docker_flags=()
      case "''${docker_mode}" in
        host)
          docker_sock="/var/run/docker.sock"
          case "''${DOCKER_HOST:-}" in
            "") ;;
            unix://*) docker_sock="''${DOCKER_HOST#unix://}" ;;
            *)
              echo "${agent.name}: docker access needs a unix:// DOCKER_HOST, got ''${DOCKER_HOST}" >&2
              exit 1
              ;;
          esac

          if [ ! -S "''${docker_sock}" ]; then
            echo "${agent.name}: docker access requested but ''${docker_sock} is not a socket" >&2
            exit 1
          fi

          # The socket is root:docker 0660 while the container runs as the
          # calling user's uid:gid, whose *primary* group is not docker - so
          # the socket's group has to be added explicitly or every call comes
          # back as a permission denied on /var/run/docker.sock.
          docker_flags=(
            --group-add "$(stat -c %g "''${docker_sock}")"
            -v "''${docker_sock}:/var/run/docker.sock"
            -v "$(readlink -f "$(which docker)"):/usr/local/bin/docker:ro"
          )
          ;;
        dind)
          # The sandbox reaches the sidecar by container name, which needs a
          # user-defined network: the default bridge has no name resolution,
          # and host networking has no container names to resolve at all.
          # Publishing the daemon on the host's loopback instead would hand
          # an unauthenticated root-equivalent API to every process on the
          # host, which is most of what this mode exists to avoid.
          if [ "''${network_mode}" = "host" ]; then
            echo "${agent.name}: docker=dind cannot be combined with host networking; use --docker=host, or drop the host network" >&2
            exit 1
          fi

          dind_name="${agent.name}-dind-$$"

          # Image cache keyed by profile so repeat sessions do not re-pull
          # everything; the daemon container itself is disposable.
          dind_volume="${agent.name}-dind-''${profile_name}"

          if [ -z "''${network_mode}" ]; then
            # Nothing chose a network, so make a throwaway one for this
            # session.  It has to be user-defined for the same DNS reason -
            # and since docker's embedded DNS is what resolves the sidecar's
            # name, the resolv.conf override has to go, exactly as the block
            # above drops it for an explicitly chosen user-defined network.
            dind_network="${agent.name}-net-$$"
            docker network create "''${dind_network}" >/dev/null
            network_mode="''${dind_network}"
            network_flags=(--network "''${dind_network}")
            resolv_mount=()
          fi

          # DOCKER_TLS_CERTDIR= turns off dind's default TLS-on-2376 in
          # favour of plain TCP on 2375.  Nothing is published to the host,
          # so the daemon is reachable only from this network - though note
          # that on a profile's own network, every other container on it
          # (the MCP fleet, say) can reach it too.
          #
          # The sandbox's mounts are repeated into the sidecar at the same
          # paths, because a `-v` from inside the sandbox is resolved by
          # *this* daemon: without them every bind mount of a repo would
          # silently turn into an empty directory.
          echo "Starting docker-in-docker sidecar..."
          docker run -d --rm \
            --name "''${dind_name}" \
            --privileged \
            --network "''${network_mode}" \
            -e DOCKER_TLS_CERTDIR= \
            -v "''${dind_volume}:/var/lib/docker" \
            "''${volume_mounts[@]}" \
            docker:dind \
            --host=tcp://0.0.0.0:2375 >/dev/null

          # The container is up well before the daemon is listening, so wait
          # for it to actually answer rather than racing the agent's first call.
          dind_ready=false
          for _ in {1..60}; do
            if docker exec "''${dind_name}" docker version >/dev/null 2>&1; then
              dind_ready=true
              break
            fi
            sleep 0.5
          done
          if ! "''${dind_ready}"; then
            echo "${agent.name}: the docker-in-docker sidecar did not come up" >&2
            docker logs "''${dind_name}" || true
            exit 1
          fi

          docker_flags=(
            -e "DOCKER_HOST=tcp://''${dind_name}:2375"
            -v "$(readlink -f "$(which docker)"):/usr/local/bin/docker:ro"
          )
          ;;
      esac

      nix_bin_dir="$(dirname "$(readlink -f "$(which nix)")")"
      sandbox_path="''${nix_bin_dir}:/root/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

      # --user is required so that files created/modified in the volume mount
      # are owned by the calling user rather than root.
      # HOME must point to a world-writable path since the container user is
      # a dynamic UID with no real home directory.
      docker run --rm -it \
        --user "$(id -u):$(id -g)" \
        -e HOME=/home/user \
        -e TERM="''${TERM}" \
        -e NIX_REMOTE=daemon \
        -e PATH="''${sandbox_path}" \
        -e SANDBOX_PATH="''${sandbox_path}" \
        "''${network_flags[@]}" \
        "''${docker_flags[@]}" \
        "''${env_flags[@]}" \
        "''${env_file_flags[@]}" \
        "''${agent_env[@]}" \
        --workdir "''${sandbox_dir}" \
        "''${volume_mounts[@]}" \
        -v "/nix:/nix:ro" \
        -v "/nix/var/nix/daemon-socket/socket:/nix/var/nix/daemon-socket/socket" \
        -v "/etc/nix/nix.conf:/etc/nix/nix.conf:ro" \
        "''${resolv_mount[@]}" \
        "''${agent_mounts[@]}" \
        "''${image_name}" "''${agent_args[@]}" "''${passthrough_args[@]}"
    '';
  };
}
