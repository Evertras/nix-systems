{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.desktop.dwm;
in {
  options.evertras.desktop.dwm = { enable = mkEnableOption "dwm"; };

  config = mkIf cfg.enable {
    services.xserver = {
      displayManager.defaultSession = "none+dwm";

      windowManager.dwm = {
        enable = true;
        package = pkgs.dwm.overrideAttrs { src = ./src; };
      };
    };
  };
}
