{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.desktop.dwm;
  patches = import ./patches.nix { lib = lib; };
  theme = config.evertras.themes.selected;
in {
  options.evertras.desktop.dwm = {
    enable = mkEnableOption "dwm";

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
  };

  config = mkIf cfg.enable {
    services.xserver = {
      displayManager.defaultSession = "none+dwm";

      windowManager.dwm = let
        customDwm = import ../../../../shared/dwm {
          inherit lib pkgs theme;
          opts = {
            autostartCmds = [
              "while ! styli.sh -s '${theme.inspiration}' &> /tmp/dwm-stylishlog; do sleep 1s; done"
              # For some reason this needs a kick
              "systemctl restart --user pipewire"
            ];
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
