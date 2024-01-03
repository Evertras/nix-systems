{ lib, ... }:
with lib;
let themes = import ./themes.nix;
in {
  options.evertras.themes = {
    selected = mkOption {
      type = with types; attrsOf anything;
      default = themes.mint;
    };
  };
}
