{ lib, pkgs, ... }:

let
  themes = import ../../themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Sky"; };

  headphonesMac = "EC:66:D1:B8:95:88";

  gpgKey = "ABFFF058F479311F";
in {
  imports = [ ../modules ../../themes/select.nix ];

  evertras.themes.selected = theme;

  evertras.home = {
    core.username = "evertras";

    shell = {
      inherit gpgKey;

      spotify.enable = true;
    };

    desktop = {
      enable = true;
      kbLayout = "jp";

      i3 = {
        monitorNetworkInterface = "wlo1";
        monitorNetworkWireless = true;
        # Pipewire doesn't seem to want to start until
        # something kicks it, so kick it
        extraStartupCommand = ''
          systemctl restart --user pipewire
        '';
        keybindOverrides = let brightnessIncrement = "10";
        in {
          XF86MonBrightnessUp =
            "exec ~/.evertras/i3funcs/brightnessChange.sh ${brightnessIncrement}%+";
          XF86MonBrightnessDown =
            "exec ~/.evertras/i3funcs/brightnessChange.sh ${brightnessIncrement}%-";
          XF86AudioRaiseVolume = "exec ~/.evertras/i3funcs/volumeUp.sh";
          XF86AudioLowerVolume = "exec ~/.evertras/i3funcs/volumeDown.sh";
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

      # CLI audio controller
      pamixer
    ];

    # TODO: move all this out into a configurable module
    file = {
      ".evertras/i3funcs/brightnessChange.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          level=$(brightnessctl -m set "$1" | awk -F, '{gsub(/%$/, "", $4); print $4}')
          notify-send "Brightness $level%" \
            -i brightnesssettings \
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
              -u critical -i audio-headset
          else
            notify-send "Headphones connected" -t 2000 -i audio-headset
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
              -u critical -i audio-headset
          else
            notify-send "Headphones disconnected" -t 2000 -i audio-headset
          fi
        '';
      };

      ".evertras/i3funcs/volumeUp.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          logfile=/tmp/last-volumeUp.log
          pamixer -i 5 &> $logfile
          if [ $? != 0 ]; then
            notify-send "Volume up failure" "$(cat $logfile)" \
              -u critical -i volume-knob
            exit 1
          fi

          value=$(pamixer --get-volume)
          notify-send "Volume $value%" \
            -i volume-knob \
            -h string:synchronous:volume \
            -h "int:value:$value"
        '';
      };

      ".evertras/i3funcs/volumeDown.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          logfile=/tmp/last-volumeDown.log
          pamixer -d 5 &> $logfile
          if [ $? != 0 ]; then
            notify-send "Volume down failure" "$(cat $logfile)" \
              -u critical -i volume-knob
            exit 1
          fi

          value=$(pamixer --get-volume)
          notify-send "Volume $value%" \
            -i volume-knob \
            -h string:synchronous:volume \
            -h "int:value:$value"
        '';
      };
    };

    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };
}
