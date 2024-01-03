{ config, lib, ... }:
with lib;
let cfg = config.evertras.themes;
in {
  options.evertras.themes = {
    selected = mkOption {
      type = types.str;
      default = "mint";
    };
  };
}
