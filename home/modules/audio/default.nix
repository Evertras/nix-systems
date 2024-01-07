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

      # TODO: This should probably be its own package in the store somewhere
      file = let
        volumeNotify = ''
          if [ $? != 0 ]; then
            notify-send "Volume failure" "$(cat $logfile)" \
              -u critical -i volume-knob
            exit 1
          fi

          value=$(pamixer --get-volume)
          msg="Volume $value%"

          if [ $(pamixer --get-mute) == "true" ]; then
            msg="Volume $value% (MUTE)"
          fi

          notify-send "$msg" \
            -t 1000 \
            -i volume-knob \
            -h string:synchronous:volume \
            -h "int:value:$value"
        '';
      in {
        ".evertras/funcs/volumeUp.sh" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            logfile=/tmp/last-volumeUp.log
            pamixer -i ${toString cfg.volumeIncrement} --set-limit ${
              toString cfg.volumeLimit
            } &> $logfile

            ${volumeNotify}
          '';
        };

        ".evertras/funcs/volumeDown.sh" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            logfile=/tmp/last-volumeDown.log
            pamixer -d ${toString cfg.volumeIncrement} &> $logfile

            ${volumeNotify}
          '';
        };

        ".evertras/funcs/volumeMuteToggle.sh" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            logfile=/tmp/last-volumeMute.log
            if [ $(pamixer --get-mute) == "false" ]; then
              pamixer -m &> $logfile
            else
              pamixer -u &> $logfile
            fi

            ${volumeNotify}
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
