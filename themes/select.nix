{ lib, ... }:
with lib; {
  options.evertras.themes = {
    selected = mkOption {
      type = types.str;
      default = "mint";
    };
  };
}
