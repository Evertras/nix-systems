{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.desktop.windowmanager.dwm;
  patches = import ./patches.nix { lib = lib; };
  theme = config.evertras.themes.selected;
in {
  options.evertras.desktop.windowmanager.dwm = {
    enable = mkEnableOption "dwm";

    borderpx = mkOption {
      description = "The size of borders around windows";
      type = types.int;
      default = 1;
    };

    browser = mkOption {
      type = types.str;
      default = "librewolf";
      description = "Browser to open with hotkey";
    };

    terminal = mkOption {
      type = types.str;
      default = "st";
      description = "Terminal to use";
    };

    lock = mkOption {
      type = types.str;
      default = "slock";
      description = "Lock command to use";
    };

    modKey = mkOption {
      type = types.str;
      default = "Mod4Mask";
      description = ''
        The modifier key to use.

        Mod4Mask is the windows/cmd super key.

        Mod1Mask is the alt key.
      '';
    };

    autostartCmds = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Commands to run on startup";
    };
  };

  config = mkIf cfg.enable {
    services.xserver = {
      displayManager.defaultSession = "none+dwm";

      windowManager.dwm = let
        customDwm = import ../../../../shared/dwm {
          inherit lib pkgs theme;
          opts = {
            autostartCmds = cfg.autostartCmds;
            borderpx = cfg.borderpx;
            browser = cfg.browser;
            lock = cfg.lock;
            terminal = cfg.terminal;
            fontSize = 16;
            gappx = 20;
            modKey = cfg.modKey;
          };
        };
      in {
        enable = true;
        package = customDwm;
      };
    };
  };
}
