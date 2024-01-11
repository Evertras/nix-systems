{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.desktop.dwm;
  theme = config.evertras.themes.selected;
  customDwm = import ../../../../shared/dwm { inherit lib pkgs theme; };
in {
  options.evertras.home.desktop.dwm = { enable = mkEnableOption "dwm"; };

  config = mkIf cfg.enable { home.packages = [ customDwm ]; };
}
