{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.desktop.dwm;
  patches = import ./patches.nix { };
in {
  options.evertras.desktop.dwm = { enable = mkEnableOption "dwm"; };

  config = mkIf cfg.enable {
    services.xserver = {
      displayManager.defaultSession = "none+dwm";

      windowManager.dwm = let
        basePatch = patches.mkBasePatch { terminal = "kitty"; };
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
