{ lib, ... }:
with lib; {
  # To be applied to individual shell rcs in ../shells/
  options.evertras.home.shell.env = {
    vars = mkOption {
      description = "Environment variables to apply to all shells";
      type = with types; attrsOf str;
      default = { };
    };
  };
}
