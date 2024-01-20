{ config, lib, pkgs, ... }:

let
  cfg = config.evertras.home.desktop.st;
  theme = config.evertras.themes.selected;
  patchlib = import ./patch.nix { };
  catppuccinPalette = import ../../../../shared/themes/palette-catppuccin.nix;
  colorsFrappe = catppuccinPalette.Frappe;
  mainPatch = patchlib.mkPatch { };
in {
  options.evertras.home.desktop.browsers.surf = with lib; {
    enable = mkEnableOption "surf";
  };

  config = lib.mkIf cfg.enable {
    home.packages = let patchList = [ mainPatch ];
    in [
      (pkgs.surf.overrideAttrs (self: super: {
        src = ./src;
        patches = if super.patches == null then
          patchList
        else
          super.patches ++ patchList;
      }))
    ];
  };
}
