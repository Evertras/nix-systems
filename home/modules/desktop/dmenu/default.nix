{ config, lib, pkgs, ... }:

let
  cfg = config.evertras.home.desktop.dmenu;
  theme = config.evertras.themes.selected;
  patchlib = import ./patches { };
in {
  options.evertras.home.desktop.dmenu = with lib; {
    enable = mkEnableOption "dmenu";
  };

  config = lib.mkIf cfg.enable {
    home.packages = let
      patchColor = patchlib.mkColorPatch { colors = theme.colors; };

      patchList = lib.lists.flatten [ patchColor ];
    in [
      (pkgs.dmenu.overrideAttrs (self: super: {
        patches = if super.patches == null then
          patchList
        else
          super.patches ++ patchList;
      }))
    ];
  };
}
