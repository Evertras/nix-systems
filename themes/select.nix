{ config, lib, ... }:
with lib;
let cfg = config.evertras.themes;
in {
  # Defines a bunch of constants for use in other
  # modules to create a consistent theme that can be
  # easily switched
  options.evertras.themes = {
    selected = mkOption {
      type = types.str;
      default = "mint";
    };
  };
}
