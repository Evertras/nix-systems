{ lib, pkgs, ... }:
with lib;
let themes = import ./themes.nix { inherit pkgs lib; };
in {
  options.evertras.themes = {
    selected = mkOption {
      type = with types; attrsOf anything;
      default = themes.mint;
    };
  };
}
