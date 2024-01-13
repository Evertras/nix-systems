{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.desktop.dwm;
  theme = config.evertras.themes.selected;
  customDwm = import ../../../../shared/dwm {
    inherit lib pkgs theme;
    opts = {
      fontSize = 16;
      gappx = 20;
      lock = cfg.lock;
      modKey = cfg.modKey;
      terminal = cfg.terminal;
    };
  };
in {
  options.evertras.home.desktop.dwm = {
    enable = mkEnableOption "dwm";
    terminal = mkOption {
      type = types.str;
      default = "kitty";
    };

    modKey = mkOption {
      type = types.str;
      default = "Mod4Mask";
      description = ''
        The modifier key to use for dwm.

        Mod4Mask is the windows/cmd super key.
        Mod1Mask is the alt key.
      '';
    };

    lock = mkOption { type = types.str; };
  };

  config = let systemfile-path = ".evertras/systemfiles/dwm.desktop";
  in mkIf cfg.enable {
    home.packages = [ customDwm ];

    home.file = {
      "${systemfile-path}" = {
        text = ''
          [Desktop Entry]
          Name=dwm-nix-hm
          Comment=dynamic window manager via home-manager
          Exec=${customDwm}/bin/dwm
          Type=XSession
          DesktopNames=dwm
        '';
      };
    };

    # This unfortunately seems necessary if we're not using NixOS...
    evertras.home.shell.funcs = {
      "install-dwm-without-nixos".body = ''
        linkfile=/usr/share/xsessions/dwm-nix-hm.desktop
        echo "Upserting linkfile $linkfile"
        sudo rm -f "$linkfile"
        sudo ln -s ~/${systemfile-path} "$linkfile"
      '';
    };
  };
}
