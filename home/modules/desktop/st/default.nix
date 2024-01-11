{ config, lib, pkgs, ... }:

let
  cfg = config.evertras.home.desktop.st;
  theme = config.evertras.themes.selected;
  patchlib = import ./patch.nix { };
  mainPatch = patchlib.mkPatch {
    /* colors = theme.colors;
       fontName = theme.fonts.mono.name;
       fontSize = 16;
    */
  };
in {
  options.evertras.home.desktop.st = with lib; {
    enable = mkEnableOption "st";
  };

  config = lib.mkIf cfg.enable {
    home.packages = let patchList = [ mainPatch ];
    in [
      (pkgs.st.overrideAttrs (self: super: {
        src = ./src;
        patches = if super.patches == null then
          patchList
        else
          super.patches ++ patchList;
      }))
    ];
  };
}
