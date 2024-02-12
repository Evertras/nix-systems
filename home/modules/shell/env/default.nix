{ config, lib, ... }:
with lib; {
  # To be applied to individual shell rcs in ../shells/
  options.home.evertras.shell.env = {
    vars = mkOption {
      description = "";
      type = with types; attrsOf str;
      default = { };
    };
  };
}
