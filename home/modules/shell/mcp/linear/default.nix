{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.evertras.home.shell.mcp.linear;

  # Server name in the generated MCP config, which is also the `mcp__<server>__`
  # prefix its tools get, so the deny rules below stay in sync with it.
  serverName = "linear";

  # The claude.ai Linear connector's server segment.  Connector tools are named
  # `mcp__claude_ai_<connector>__<tool>`.
  connectorName = "claude_ai_Linear";

  # Verb prefixes of Linear's mutating tools (create_*, save_*, delete_*,
  # merge_diff, submit_diff_review, resolve_diff_thread,
  # prepare_attachment_upload).  Every read tool is a get_*, list_*, search_* or
  # extract_*, so denying these prefixes can't catch a read tool by accident.
  writePrefixes = [
    "create"
    "delete"
    "merge"
    "prepare"
    "resolve"
    "save"
    "submit"
  ];

  denyWriteRules = map (p: "mcp__${serverName}__${p}_*") writePrefixes;
in
{
  options.evertras.home.shell.mcp.linear = {
    enable = mkEnableOption ''
      a read-only Linear MCP server.  Like sem, and unlike the fleet servers,
      this is not a container we run: Linear hosts it, so all we declare is the
      URL claude connects to.  There is no credential for us to hold either -
      claude does its own OAuth against Linear the first time (`/mcp` inside a
      sandbox), and the token persists because ~/.claude is mounted read-write.

      Read-only is enforced in two independent places, neither of which is the
      claude.ai connector's own per-tool controls - those were tried and writes
      still got through, which is why the connector is disconnected at
      claude.ai/customize/connectors and denied here as well:

      1. The endpoint.  Linear serves read tools on a separate URL from its
         read-write one, and the token behind the read-only URL cannot reach
         Linear's write APIs at all.  This is the guarantee that holds even if
         claude ignores every local rule.
      2. Local deny rules (`denyWrites`), which drop Linear's mutating tools
         from claude's context before it ever sees them.  This is what catches a
         mistake in (1) - a wrong `url`, or Linear changing what the read-only
         endpoint serves
    '';

    url = mkOption {
      type = types.str;
      default = "https://mcp.linear.app/mcp/readonly";
      description = ''
        Linear MCP endpoint.  The default is Linear's read-only endpoint, which
        only ever exposes read tools; its read-write sibling is
        `https://mcp.linear.app/mcp`.  Override this only if Linear moves the
        path - pointing it at the read-write endpoint defeats the module, though
        `denyWrites` still fences off the write tools it would then serve.
      '';
    };

    global = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to load Linear in every sandbox via `claude-sandbox.globalMcp`,
        so no per-profile wiring is needed.  It costs a chunk of context in
        every sandbox (Linear exposes a lot of read tools), so set this to
        false to keep it out of unrelated sandboxes and instead wire
        `...mcp.claude.paths.linear` into the profiles that want it, the way
        the github server is wired.

        The deny rules are sandbox-wide either way.
      '';
    };

    denyWrites = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to deny Linear's mutating tools by name in every sandbox
        (`mcp__linear__save_*`, `create_*`, `delete_*`, ...), via
        `claude-sandbox.denyPermissions`.

        On the read-only endpoint these rules match nothing, which is the point:
        they are the backstop for the endpoint being wrong rather than the
        primary control.  Leave this on unless a rule starts shadowing a read
        tool that Linear has named with a write verb.
      '';
    };

    denyConnector = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to deny the claude.ai Linear connector's tools in every sandbox.
        The connector is configured on claude.ai rather than here, points at the
        read-write endpoint, and loads automatically in any claude signed in
        with the claude.ai account - including after an admin re-provisions it
        or someone reconnects it for another workflow.

        Disconnecting it at claude.ai/customize/connectors is the real fix; this
        rule is what keeps it from quietly coming back, so it is worth keeping
        even once the connector is gone.
      '';
    };
  };

  config = mkIf cfg.enable {
    # An HTTP MCP config claude loads directly; no fleet container, and no
    # credential passed in, since Linear hosts the server and authenticates
    # claude itself over OAuth.
    evertras.home.shell.mcp.claude = {
      enable = true;
      files.${serverName}.servers.${serverName} = {
        type = "http";
        url = cfg.url;
      };
    };

    evertras.home.shell.claude-sandbox = {
      globalMcp = optional cfg.global config.evertras.home.shell.mcp.claude.paths.${serverName};

      # Deny rather than ask: a deny rule drops the tools from claude's context
      # entirely, and a --yolo sandbox has no prompts to say no at anyway.  The
      # connector rule is bare (whole server), since none of its tools should
      # ever be reachable.
      denyPermissions =
        optionals cfg.denyWrites denyWriteRules ++ optional cfg.denyConnector "mcp__${connectorName}";

      # Same shape as the GitHub guidance in the baked instructions: tell the
      # agent up front that Linear writes are not available, so it explains
      # instead of discovering it by failing.
      extraInstructions = [
        ''
          The Linear MCP server is read-only and you have no credentials to write to Linear. This includes creating or editing issues, comments, projects, documents, and labels, or any other operation that modifies Linear state. Read-only Linear operations work fine. If a task appears to require writing to Linear, don't attempt it — stop and explain that you lack write access instead.
        ''
      ];
    };
  };
}
