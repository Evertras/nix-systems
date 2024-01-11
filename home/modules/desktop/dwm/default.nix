{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.desktop.dwm;
  theme = config.evertras.themes.selected;
  customDwm = import ../../../../shared/dwm { inherit lib pkgs theme; };
in {
  options.evertras.home.desktop.dwm = { enable = mkEnableOption "dwm"; };

  config = mkIf cfg.enable {
    home.packages = [ customDwm ];

    home.file = {
      ".evertras/systemfiles/dwm.desktop" = {
        text = ''
          [Desktop Entry]
          Name=dwm
          Comment=dynamic window manager
          Exec=${customDwm}/bin/dwm
          Type=XSession
          DesktopNames=dwm
        '';
      };
    };

    # This unfortunately seems necessary if we're not using NixOS...
    evertras.home.shell.funcs = {
      "install-dwm-without-nixos".body = ''
        sudo ln -s ~/.evertras/systemfiles/dwm.desktop /usr/share/xsessions/dwm.desktop
      '';
    };
  };
}
