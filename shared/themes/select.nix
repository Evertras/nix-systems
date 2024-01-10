{ config, lib, pkgs, ... }:
with lib;
let
  themes = import ./themes.nix { inherit pkgs lib; };
  selected = config.evertras.themes.selected;
in {
  options.evertras.themes = {
    selected = mkOption {
      type = with types; attrsOf anything;
      default = themes.mint;
    };
  };
}
