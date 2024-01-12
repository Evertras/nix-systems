{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.desktop.dwm;
  patches = import ./patches.nix { lib = lib; };
  theme = config.evertras.themes.selected;
in {
  options.evertras.desktop.dwm = {
    enable = mkEnableOption "dwm";
    terminal = mkOption {
      type = types.str;
      default = "st";
      description = "Terminal to use";
    };
  };

  config = mkIf cfg.enable {
    services.xserver = {
      displayManager.defaultSession = "none+dwm";

      windowManager.dwm = let
        customDwm = import ../../../../shared/dwm {
          inherit lib pkgs theme;
          opts.terminal = cfg.terminal;
        };
      in {
        enable = true;
        package = customDwm;
      };
    };
  };
}
