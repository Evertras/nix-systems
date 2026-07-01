{ everlib, ... }:
{
  # Each MCP-related concern lives in its own subdirectory (claude-mcp,
  # k8s-mcp, ...).  Auto-import them so adding a new one needs no wiring.
  imports = everlib.allSubdirs ./.;
}
