{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.audio;

in {
  options.evertras.home.audio = {
    enable = mkEnableOption "audio";

    enableDesktop = mkEnableOption "additional audio desktop tools";

    headphonesMacAddress = mkOption {
      description = "If supplied, add bluetooth connection helpers";
      type = with types; nullOr str;
      default = null;
    };

    volumeLimit = mkOption {
      description = ''
        0-100 max volume that can be raised to via volume controls.
        Does NOT apply a global limit!
      '';
      default = 40;
    };

    volumeIncrement = mkOption {
      type = types.int;
      default = 5;
    };
  };

  config = let
    desktopPackages = if cfg.enableDesktop then [ pkgs.pavucontrol ] else [ ];
  in mkIf cfg.enable {
    home = {
      packages = with pkgs; [ libnotify pamixer ] ++ desktopPackages;

      file = {
        ".evertras/funcs/volumeUp.sh" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            logfile=/tmp/last-volumeUp.log
            pamixer -i ${toString cfg.volumeIncrement} --set-limit ${
              toString cfg.volumeLimit
            } &> $logfile
            if [ $? != 0 ]; then
              notify-send "Volume up failure" "$(cat $logfile)" \
                -u critical -i volume-knob
              exit 1
            fi

            value=$(pamixer --get-volume)
            notify-send "Volume $value%" \
              -t 1000 \
              -i volume-knob \
              -h string:synchronous:volume \
              -h "int:value:$value"
          '';
        };

        ".evertras/funcs/volumeDown.sh" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            logfile=/tmp/last-volumeDown.log
            pamixer -d ${toString cfg.volumeIncrement} &> $logfile
            if [ $? != 0 ]; then
              notify-send "Volume down failure" "$(cat $logfile)" \
                -u critical -i volume-knob
              exit 1
            fi

            value=$(pamixer --get-volume)
            notify-send "Volume $value%" \
              -t 1000 \
              -i volume-knob \
              -h string:synchronous:volume \
              -h "int:value:$value"
          '';
        };

        ".evertras/funcs/headphonesConnect.sh" =
          mkIf (cfg.headphonesMacAddress != null) {
            executable = true;
            text = ''
              #!/usr/bin/env bash
              logfile=/tmp/last-headphonesConnect.log
              bluetoothctl connect ${cfg.headphonesMacAddress} &> $logfile
              if [ $? != 0 ]; then
                notify-send "Headphones connect failure" "$(cat $logfile)" \
                  -u critical -i audio-headset
              else
                notify-send "Headphones connected" -t 2000 -i audio-headset
              fi
            '';
          };

        ".evertras/funcs/headphonesDisconnect.sh" =
          mkIf (cfg.headphonesMacAddress != null) {
            executable = true;
            text = ''
              #!/usr/bin/env bash
              logfile=/tmp/last-headphonesDisconnect.log
              bluetoothctl disconnect ${cfg.headphonesMacAddress} &> $logfile
              if [ $? != 0 ]; then
                notify-send "Headphones disconnect failure" "$(cat $logfile)" \
                  -u critical -i audio-headset
              else
                notify-send "Headphones disconnected" -t 2000 -i audio-headset
              fi
            '';
          };
      };
    };
  };
}
