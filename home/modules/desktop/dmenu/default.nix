{ config, lib, pkgs, ... }:

let
  cfg = config.evertras.home.desktop.dmenu;
  theme = config.evertras.themes.selected;
  patchlib = import ./patch.nix { };
  mainPatch = patchlib.mkPatch {
    colors = theme.colors;
    fontName = theme.fonts.main.name;
    fontSize = 16;
    # DWM top bar height
    lineHeight = 26;
  };
in {
  options.evertras.home.desktop.dmenu = with lib; {
    enable = mkEnableOption "dmenu";
  };

  config = lib.mkIf cfg.enable {
    home.packages = let patchList = [ mainPatch ];
    in [
      (pkgs.dmenu.overrideAttrs (self: super: {
        src = ./src;
        patches = if super.patches == null then
          patchList
        else
          super.patches ++ patchList;
      }))
    ];
  };
}
