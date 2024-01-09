{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.desktop.dwm;
  patches = import ./patches.nix { lib = lib; };
  theme = config.evertras.themes.selected;
in {
  options.evertras.desktop.dwm = { enable = mkEnableOption "dwm"; };

  config = mkIf cfg.enable {
    services.xserver = {
      displayManager.defaultSession = "none+dwm";

      windowManager.dwm = let
        basePatch = patches.mkBasePatch {
          terminal = "kitty";
          colorPrimary = theme.colors.primary;
          colorText = theme.colors.text;
          colorBackground = theme.colors.background;
          fontName = theme.fonts.main.name;
          fontSize = 14;
        };
        patchList = [ basePatch ];
      in {
        enable = true;
        package = pkgs.dwm.overrideAttrs (self: super: {
          src = ./src;
          patches = if super.patches == null then
            patchList
          else
            super.patches ++ patchList;
        });
      };
    };
  };
}
