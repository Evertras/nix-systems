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

    };

    evertras.home.shell.funcs = let
      volumeNotify = cmd: ''
        if ! ${cmd}; then
          notify-send "Volume failure" "$(cat $logfile)" \
            -u critical -i volume-knob
          exit 1
        fi

        value=$(pamixer --get-volume)
        msg="Volume $value%"

        if [ "$(pamixer --get-mute)" == "true" ]; then
          msg="Volume $value% (MUTE)"
        fi

        notify-send "$msg" \
          -t 1000 \
          -i volume-knob \
          -h string:synchronous:volume \
          -h "int:value:$value"
      '';

      incr = toString cfg.volumeIncrement;
      limit = toString cfg.volumeLimit;

      headphoneFuncs = if cfg.headphonesMacAddress != null then {
        headphones-connect.body = ''
          logfile=/tmp/last-headphonesConnect.log

          if ! bluetoothctl connect "${cfg.headphonesMacAddress}" &> $logfile; then
            notify-send "Headphones connect failure" "$(cat $logfile)" \
              -u critical -i audio-headset
            exit 1
          fi

          notify-send "Headphones connected" -t 2000 -i audio-headset
        '';

        headphones-disconnect.body = ''
          logfile=/tmp/last-headphonesDisconnect.log

          if ! bluetoothctl disconnect "${cfg.headphonesMacAddress}" &> $logfile; then
            notify-send "Headphones disconnect failure" "$(cat $logfile)" \
              -u critical -i audio-headset
            exit 1
          fi

          notify-send "Headphones disconnected" -t 2000 -i audio-headset
        '';

        headphones-toggle.body = ''
          connected=$(bluetoothctl info ${cfg.headphonesMacAddress} | grep Connected | awk '{print $2}')

          if [ "$connected" == 'yes' ]; then
            headphones-disconnect
          else
            headphones-connect
          fi
        '';
      } else
        { };

      volumeFuncs = {
        volume-up.body = ''
          logfile=/tmp/last-volumeUp.log

          ${volumeNotify "pamixer -i ${incr} --set-limit ${limit} &> $logfile"}
        '';

        volume-down.body = ''
          logfile=/tmp/last-volumeDown.log

          ${volumeNotify "pamixer -d ${incr} &> $logfile"}
        '';

        volume-mute-toggle.body = ''
          logfile=/tmp/last-volumeMute.log
          if [ "$(pamixer --get-mute)" == "false" ]; then
            flag="-m"
          else
            flag="-u"
          fi

          ${volumeNotify ''pamixer "$flag" &> $logfile''}
        '';
      };
    in (volumeFuncs // headphoneFuncs);
  };
}
