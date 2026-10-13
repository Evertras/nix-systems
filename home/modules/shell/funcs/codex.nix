{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.evertras.home.shell.codex-sandbox;

  # Deliberately the claude-sandbox options, not a copy of them: codex-sandbox
  # is a mirror, so every profile, global MCP config, and instruction
  # contributed there applies here too with no second definition to drift.
  sandboxCfg = config.evertras.home.shell.claude-sandbox;

  sandbox = import ./sandbox-lib.nix {
    inherit lib pkgs;
    cfg = sandboxCfg;
  };

  # Translate a Claude MCP config (`{ mcpServers = { <name> = {...}; }; }`)
  # into codex `-c` overrides, one `key=value` per line.  Codex has no
  # equivalent of `--mcp-config <file>`; its servers live under
  # `mcp_servers.<name>` in config.toml, which `-c` can set per session.
  #
  # Only the fields codex understands are carried over: command/args/env for
  # stdio servers, url/headers for HTTP ones.  Claude's `type` is dropped,
  # since codex infers the transport from `url` vs `command`, and refuses a
  # server that mixes the two sets of fields.  Values are emitted with
  # `tojson`, and a JSON string or array of strings is also valid TOML, which
  # is what codex parses `-c` values as.
  mcpToCodex = pkgs.writeText "codex-sandbox-mcp.jq" ''
    (.mcpServers // {}) | to_entries[] | .key as $n | .value |
      if .command then
        "mcp_servers.\($n).command=\(.command | tojson)",
        (if .args then "mcp_servers.\($n).args=\(.args | map(tostring) | tojson)" else empty end),
        ((.env // {}) | to_entries[] | "mcp_servers.\($n).env.\(.key)=\(.value | tostring | tojson)")
      elif .url then
        "mcp_servers.\($n).url=\(.url | tojson)",
        ((.headers // {}) | to_entries[] | "mcp_servers.\($n).http_headers.\(.key)=\(.value | tostring | tojson)")
      else
        empty
      end
  '';

  codexAgent = {
    name = "codex-sandbox";
    label = "Codex";
    image = "evertras-codex-sandbox";

    # jq on the host, to translate MCP configs and quote the instructions.
    runtimeInputs = [ pkgs.jq ];

    # Installed from npm, so it lands in /usr/local/bin on the shared node
    # base, already on the sandbox PATH for whatever uid runs it.
    dockerfile = ''
      RUN npm install -g @openai/codex@${cfg.version}

      ENTRYPOINT ["codex"]
    '';

    prepare = ''
      # ~/.codex holds codex's auth, config.toml, and session history.  It is
      # shared with the host like ~/.claude is for claude, so a `codex login`
      # done on either side works on both.  Created first so docker doesn't
      # make it root-owned.
      mkdir -p "''${HOME}/.codex"
      agent_mounts=(-v "''${HOME}/.codex:/home/user/.codex")

      # Codex only reads AGENTS.md from the git root down to the workdir (and
      # its own ~/.codex/AGENTS.md), so a file at /sandbox the way claude gets
      # CLAUDE.md would never be seen.  Hand the same text over as developer
      # instructions instead: the profile's combined file when it has one,
      # otherwise the global instructions alone.  jq -Rs quotes it as a JSON
      # string, which is also a valid TOML string.
      instructions_file="''${profile_instructions:-${sandbox.globalInstructionsFile}}"

      agent_args=(
        -c check_for_update_on_startup=false
        -c "developer_instructions=$(jq -Rs . < "''${instructions_file}")"
      )

      # Codex's own command sandbox is bubblewrap, which needs to create a
      # user namespace - exactly what docker's default seccomp profile
      # forbids, so every command fails.  Loosening seccomp would weaken the
      # container, which is the real boundary here, to make room for a second
      # one nested inside it; instead turn codex's sandbox off and let the
      # container do the job, as it does for claude.  Approval prompts are
      # unaffected.
      #
      # --yolo is codex's spelling of skip-every-prompt, which turns the
      # sandbox off as well.
      if "''${yolo}"; then
        agent_args+=(--dangerously-bypass-approvals-and-sandbox)
      else
        agent_args+=(-c 'sandbox_mode="danger-full-access"')
      fi

      # The same MCP configs claude gets, translated into `-c` overrides on
      # the host.  Nothing to mount: stdio servers (sem) are baked into the
      # image, and HTTP ones are reached by URL.
      for mcp_config in "''${mcp_configs[@]}"; do
        if ! mcp_overrides="$(jq -r -f ${mcpToCodex} "''${mcp_config}")"; then
          echo "codex-sandbox: failed to read MCP config ''${mcp_config}" >&2
          exit 1
        fi
        while IFS= read -r override; do
          if [ -n "''${override}" ]; then
            agent_args+=(-c "''${override}")
          fi
        done <<< "''${mcp_overrides}"
      done
    '';
  };
in
{
  options.evertras.home.shell.codex-sandbox = {
    enable = mkEnableOption ''
      codex-sandbox, an OpenAI Codex mirror of claude-sandbox.  It takes no
      configuration of its own: profiles (`-p`/`-l`), mounted dirs, scratch
      directories, docker modes, env, networks, MCP configs (`globalMcp`,
      profile `mcp`, `-m`), `extraDockerfile`, and instructions all come from
      the `claude-sandbox` options, and it accepts the same flags.

      What does not carry over is claude-specific: `denyPermissions` (codex
      has no equivalent glob deny), and claude's own ~/.claude skills and
      settings.  Codex uses ~/.codex instead, mounted read-write.

      A profile's instructions are passed as codex developer instructions
      rather than an AGENTS.md, since codex would not find one at /sandbox
    '';

    version = mkOption {
      type = types.str;
      default = "latest";
      example = "0.50.0";
      description = ''
        `@openai/codex` npm version baked into the image.  `latest` resolves
        when the image is built, so pick up a new release with
        `codex-sandbox --update`.
      '';
    };
  };

  config = mkIf cfg.enable {
    evertras.home.shell.funcs.codex-sandbox = sandbox.mkSandboxFunc codexAgent;
  };
}
