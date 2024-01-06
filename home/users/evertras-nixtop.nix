{ lib, pkgs, ... }:

let
  themes = import ../../themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Sky"; };

  headphonesMac = "EC:66:D1:B8:95:88";
in {
  imports = [ ../modules ../../themes/select.nix ];

  evertras.themes.selected = theme;

  evertras.home = {
    core.username = "evertras";

    shell = { git.gpgKey = "ABFFF058F479311F"; };

    desktop = {
      enable = true;
      kbLayout = "jp";

      i3 = {
        monitorNetworkInterface = "wlo1";
        monitorNetworkWireless = true;
        keybindOverrides = let brightnessIncrement = "10";
        in {
          XF86MonBrightnessUp =
            "exec ~/.evertras/i3funcs/brightnessChange.sh ${brightnessIncrement}%+";
          XF86MonBrightnessDown =
            "exec ~/.evertras/i3funcs/brightnessChange.sh ${brightnessIncrement}%-";
          "Mod4+h" = "exec ~/.evertras/i3funcs/headphonesConnect.sh";
          "Mod4+shift+h" = "exec ~/.evertras/i3funcs/headphonesDisconnect.sh";
        };
      };
    };
  };

  home = let
  in {
    # Other local things
    packages = with pkgs; [
      # Laptop things
      brightnessctl

      # GUI audio controller
      pavucontrol
    ];

    file = {
      ".evertras/i3funcs/brightnessChange.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          level=$(brightnessctl -m set "$1" | awk -F, '{gsub(/%$/, "", $4); print $4}')
          notify-send "Brightness $level%" \
            -t 2000 \
            -h string:synchronous:screenbrightness \
            -h "int:value:$level"
        '';
      };

      ".evertras/i3funcs/headphonesConnect.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          logfile=/tmp/last-headphonesConnect.log
          bluetoothctl connect ${headphonesMac} &> $logfile
          if [ $? != 0 ]; then
            notify-send "Headphones connect failure" "$(cat $logfile)" \
              -u critical
          else
            notify-send "Headphones connected" -t 2000
          fi
        '';
      };

      ".evertras/i3funcs/headphonesDisconnect.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          logfile=/tmp/last-headphonesDisconnect.log
          bluetoothctl disconnect ${headphonesMac} &> $logfile
          if [ $? != 0 ]; then
            notify-send "Headphones disconnect failure" "$(cat $logfile)" \
              -u critical
          else
            notify-send "Headphones disconnected" -t 2000
          fi
        '';
      };
    };

    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };
}
