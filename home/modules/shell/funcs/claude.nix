{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.evertras.home.shell.claude-sandbox;

  sandbox = import ./sandbox-lib.nix { inherit lib pkgs cfg; };

  jsonFormat = pkgs.formats.json { };

  # Session settings file carrying the contributed deny rules, or null when no
  # module contributed any.  Deny is the only permission control worth anything
  # in a --yolo sandbox: it is evaluated ahead of allow rules from every
  # settings scope and still applies with --dangerously-skip-permissions, and a
  # bare tool/server name deny drops the tool from claude's context outright.
  settingsFile =
    if cfg.denyPermissions == [ ] then
      null
    else
      jsonFormat.generate "claude-sandbox-settings.json" {
        permissions.deny = cfg.denyPermissions;
      };

  claudeAgent = {
    name = "claude-sandbox";
    label = "Claude";
    image = "evertras-claude-sandbox";

    dockerfile = ''
      ENV PATH="/root/.local/bin:${"$"}{PATH}"

      RUN curl -fsSL https://claude.ai/install.sh | bash

      RUN chmod a+rx /root /root/.local /root/.local/bin \
          && mkdir -p /home/user/.local/bin \
          && ln -s /root/.local/bin/claude /home/user/.local/bin/claude

      # Global sandbox-wide instructions, baked in as the default CLAUDE.md.
      # Profiles with their own instructions mount a combined file (these plus
      # the profile's extras) over this at runtime, so this guidance always
      # applies.  Kept in sync from the single globalInstructions definition.
      COPY <<EOF /sandbox/CLAUDE.md
      ${sandbox.globalInstructions}
      EOF

      ENTRYPOINT ["claude"]
    '';

    prepare = ''
      agent_mounts=(-v "''${HOME}/.claude:/home/user/.claude")
      if [ -f "''${HOME}/.claude.json" ]; then
        agent_mounts+=(-v "''${HOME}/.claude.json:/home/user/.claude.json")
      fi

      # A profile may supply its own CLAUDE.md, mounted over the baked default.
      if [ -n "''${profile_instructions}" ]; then
        agent_mounts+=(-v "''${profile_instructions}:/sandbox/CLAUDE.md:ro")
      fi

      agent_env=(-e DISABLE_AUTOUPDATER=1)

      # Deny rules contributed by other modules (see `denyPermissions`) ride
      # in as a session settings file.  No mount is needed: /nix is already
      # bind-mounted read-only, so the store path resolves in-sandbox.
      #
      # In --yolo mode, tell claude to skip every permission prompt.  Safe
      # here because the sandbox is the blast radius, not the host - and the
      # deny rules above still apply, prompts or not.
      agent_args=(${optionalString (settingsFile != null) "--settings ${settingsFile}"})
      if "''${yolo}"; then
        agent_args+=(--dangerously-skip-permissions)
      fi

      # Mount each MCP config (read-only) at its host path under /sandbox and
      # tell claude to load it with --mcp-config.
      for mcp_config in "''${mcp_configs[@]}"; do
        rp="$(realpath "''${mcp_config}")"
        agent_mounts+=(-v "''${rp}:/sandbox''${rp}:ro")
        agent_args+=(--mcp-config "/sandbox''${rp}")
      done
    '';
  };
in
{
  options.evertras.home.shell.claude-sandbox.profiles = mkOption {
    default = { };
    description = ''
      Named claude-sandbox profiles, selected with `claude-sandbox -p <name>`
      and listed with `claude-sandbox -l`.

      codex-sandbox, when enabled, reads these same profiles (and the rest of
      the claude-sandbox options), so `codex-sandbox -p <name>` mirrors
      `claude-sandbox -p <name>`.

      Each profile preloads a set of mounted directories (read-write via
      `dirs`, read-only via `dirsRo`), an optional working directory, and
      optional CLAUDE.md instructions.  Extra `-d` flags passed on the
      command line are appended to the profile's read-write dirs, and any
      remaining args are passed through to claude.

      Directory strings are expanded by the shell at runtime, so `$HOME`
      works (but a bare `~` does not, since it is quoted).
    '';
    example = literalExpression ''
      {
        tdb = {
          dirs = [ "$HOME/dev/tdb" "$HOME/dev/tdb-docs" ];
          # Mounted :ro - readable and copyable, but unwritable.
          dirsRo = [ "$HOME/dev/tdb-legacy" ];
          # Created and git-initialized on first launch, at
          # <scratchBase>/tdb-scratch.
          scratch = true;
          # A contained daemon of its own; "host" shares the host's
          # instead - read the option's warning before choosing that.
          docker = "dind";
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
            description = "Host directories to mount into the sandbox, read-write.";
          };
          dirsRo = mkOption {
            type = types.listOf types.str;
            default = [ ];
            example = [ "$HOME/dev/some-reference-repo" ];
            description = ''
              Host directories to mount into the sandbox read-only, mounted at
              the same `/sandbox`-prefixed paths as `dirs`.  The agent can read
              and copy out of them, but the kernel refuses every write, so this
              is enforcement rather than a CLAUDE.md request not to touch them.

              Use for source/reference repos the agent should learn from but
              never edit.  Inspecting git history still works (`git log`,
              `git status`, and `git diff` tolerate an unwritable index), while
              anything that writes - `commit`, `checkout`, `fetch` - fails.

              These are appended after `dirs`, so when no `workdir` is set the
              default working directory still comes from `dirs`.
            '';
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
          scratch = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Give this profile a persistent scratch directory at
              `<scratchBase>/<profile>-scratch`, mounted read-write alongside
              its other dirs.  The directory is created and `git init`ed on
              first launch, so there is nothing to set up by hand, and a
              generated CLAUDE.md section tells the agent what it is for.

              It is for work that should outlive a session but belongs in no
              repository: notes, plans, throwaway scripts, sample data.

              The `-scratch` suffix is deliberate and not configurable: the
              basename is what gets read in isolation, and a bare profile name
              would collide with the repository the profile is named after.
              A scratch space under some other path is just an entry in
              `dirs`.
            '';
          };
          docker = mkOption {
            type = types.either types.bool (
              types.enum [
                "none"
                "host"
                "dind"
              ]
            );
            default = "none";
            example = "dind";
            description = ''
              How this profile reaches docker.  A generated CLAUDE.md section
              explains whichever mode is set, since the footguns differ.

              `"none"` (the default) gives the sandbox no docker at all.

              `"dind"` starts a docker-in-docker sidecar for the session and
              points the sandbox at it over the docker network.  The daemon is
              a separate one from the host's, with its own images, containers,
              and networks, so an agent cannot stop the host's containers or
              delete its images.  The sandbox's mounted dirs are mounted into
              the sidecar at the same paths, so `-v` arguments work with the
              paths the agent actually sees.  The image cache starts cold and
              then persists per profile in a named volume.

              `"dind"` contains mistakes, not a determined attacker: the
              sidecar runs privileged, and a privileged container can reach the
              host through `/dev`.  It also cannot be combined with
              `network = "host"`, which leaves no way to reach the sidecar by
              name; the launcher refuses that combination.

              `"host"` bind-mounts the host's docker socket, mounts the host's
              own `docker` binary at `/usr/local/bin/docker`, and adds the
              socket's group to the container user so the calls are permitted.
              This shares the host's image cache and drives real host
              containers, which is what work like Tilt builds or minikube
              needs.

              Understand what `"host"` gives up.  The docker socket is a root
              API: anything that can reach it can start a privileged container
              that bind-mounts `/`, which is full control of the host.  The
              sandbox stops being a boundary and becomes a convenience, so turn
              this on only for profiles whose work genuinely needs the host's
              own docker state, and think twice about combining it with
              `--yolo`.

              Under `"host"`, containers started from inside are siblings on
              the host, not children of the sandbox: they survive the session,
              share the host's images and networks, and are not cleaned up
              automatically.  Registry credentials are not mounted either, so
              private pulls need a `docker login` inside the sandbox (or an
              already-pulled image).

              `true` and `false` are accepted as the original spellings of
              `"host"` and `"none"`.

              A bare `--docker` flag turns on `"dind"` for a single launch;
              `--docker <mode>` and `--docker=<mode>` pick one explicitly.  All
              of them override whatever the profile sets.  Only the `=` form
              rejects an unknown mode - after the bare flag an unrecognized
              word is left alone as a passthrough arg, since it is far more
              likely to be a prompt than a typo.

              The generated CLAUDE.md section is baked per profile, so a mode
              reached only through the flag runs without it and the agent has
              to work the footguns out for itself.
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

  options.evertras.home.shell.claude-sandbox.scratchBase = mkOption {
    type = types.str;
    default = "${config.home.homeDirectory}/dev/scratch";
    defaultText = literalExpression ''"''${config.home.homeDirectory}/dev/scratch"'';
    description = ''
      Parent directory holding the per-profile scratch directories created for
      profiles with `scratch = true`, each at `<scratchBase>/<profile>-scratch`.

      One container directory keeps them out of the clone tree and gives a
      single place to exclude from backups or wipe.

      Must be an absolute path: unlike `dirs` this is not only run through the
      shell but also baked into the generated CLAUDE.md, where a `$HOME` would
      appear to the agent literally.
    '';
  };

  options.evertras.home.shell.claude-sandbox.maskFiles = mkOption {
    type = types.listOf types.str;
    default = [ ".envrc" ];
    example = [
      ".envrc"
      ".env"
    ];
    description = ''
      File names hidden in every sandbox: wherever one exists at the top level
      of a mounted dir (`dirs`, `dirsRo`, `-d`, or a scratch dir), /dev/null is
      bind-mounted over it read-only, so the agent sees an empty file and can
      neither read nor overwrite the real one.  For files that hold secrets,
      like an `.envrc` exporting API keys.

      Only each mounted dir's top level is checked, not subdirectories, and
      only files that exist at launch.  Applies to every agent, since both
      launchers read these options.
    '';
  };

  options.evertras.home.shell.claude-sandbox.extraInstructions = mkOption {
    type = types.listOf types.lines;
    default = [ ];
    description = ''
      Extra paragraphs appended to the baked, sandbox-wide CLAUDE.md (after
      the built-in guidance, before any profile's own instructions).  Meant
      for other modules to contribute always-on guidance, e.g. the sem MCP
      module telling the agent when to use its entity-level tools.
    '';
  };

  options.evertras.home.shell.claude-sandbox.extraDockerfile = mkOption {
    type = types.lines;
    default = "";
    description = ''
      Extra Dockerfile lines appended to the sandbox image build (just before
      the ENTRYPOINT).  Meant for other modules to bake tools into every
      sandbox, e.g. the sem MCP module fetching its release binary.  Changes
      here take effect on the next `claude-sandbox --rebuild`.
    '';
  };

  options.evertras.home.shell.claude-sandbox.denyPermissions = mkOption {
    type = types.listOf types.str;
    default = [ ];
    example = [ "mcp__claude_ai_Linear" ];
    description = ''
      Permission deny rules applied in every sandbox, passed to claude as a
      `--settings` file.  Meant for other modules to fence off tools the
      sandbox should never be able to call, e.g. the Linear MCP module denying
      the read-write claude.ai Linear connector.

      Deny rules are what hold in a `--yolo` sandbox: they are evaluated before
      any allow rule, from every settings scope, and still apply under
      `--dangerously-skip-permissions`.  A bare tool or server name (`Bash`,
      `mcp__claude_ai_Linear`) removes the tool from claude's context entirely;
      a scoped rule (`Bash(rm *)`, `mcp__foo__bar`) leaves the tool in place and
      blocks matching calls.

      These layer on top of the host's own ~/.claude/settings.json, which the
      sandbox already sees via the mounted ~/.claude, so put rules that should
      also apply outside the sandbox there instead.
    '';
  };

  options.evertras.home.shell.claude-sandbox.globalMcp = mkOption {
    type = types.listOf types.str;
    default = [ ];
    description = ''
      MCP server config JSON paths loaded in every sandbox, regardless of
      profile, mounted read-only and passed to claude via `--mcp-config`
      before any profile/`-m` configs.  Use for repo-agnostic servers that
      should always be available (e.g. sem).  Path strings are expanded by
      the shell at runtime, so `$HOME` works (but a bare `~` does not).
    '';
  };

  # Personal skills, available in every sandbox for free: ~/.claude is
  # bind-mounted into the container and /nix is mounted read-only there, so
  # these store symlinks resolve inside the sandbox as well as on the host.
  # `recursive` links each file individually rather than the directory, so
  # hand-placed skills in ~/.claude/skills keep working alongside these.
  config.home.file.".claude/skills/local-iteration" = {
    source = ./skills/local-iteration;
    recursive = true;
  };

  config.evertras.home.shell.funcs.claude-sandbox = sandbox.mkSandboxFunc claudeAgent;
}
