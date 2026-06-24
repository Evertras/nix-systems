# Shared option declaration for per-application notification timeouts.
# Imported by both the notifications module and the mako module so the
# structure stays defined in exactly one place.
{ lib }:
lib.mkOption {
  description = ''
    Per-application notification timeouts, in seconds. Only applies when
    using mako (Wayland).
  '';
  default = { };
  type = lib.types.submodule {
    options.kitty = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = ''
        How long notifications from kitty (e.g. Claude Code) stay on
        screen, in seconds.
      '';
    };
  };
}
