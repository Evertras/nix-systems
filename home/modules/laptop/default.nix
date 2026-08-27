{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.evertras.home.laptop;
in
{
  options.evertras.home.laptop = {
    enable = mkEnableOption "Enable laptop configuration";

    brightnessIncrement = mkOption {
      type = types.int;
      default = 10;
      description = "Brightness percentage increment for brightness changes";
    };

    suspendOnBatteryIdleMinutes = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 30;
      description = ''
        Idle minutes on battery before the machine suspends, or null to never
        suspend on its own.  On wall power it never suspends, no matter how
        long it sits there or what the lid is doing.

        Driven by swayidle, so this only does anything on a compositor that
        turns swayidle on (the niri module does).
      '';
    };
  };

  config = mkIf cfg.enable {
    evertras.home.shell.funcs =
      let
        brightnessChange = { change }: ''
          level=$(brightnessctl -m set "${change}" | awk -F, '{gsub(/%$/, "", $4); print $4}')

          # Apparently you have to know mako's flavor from
          # https://github.com/emersion/mako/pull/270/files
          # so we send multiple hints to remove duplicates
          notify-send "Brightness $level%" \
            -i brightnesssettings \
            -t 2000 \
            -h string:synchronous:evertras-screenbrightness \
            -h string:x-dunst-stack-tag:evertras-screenbrightness \
            -h "int:value:$level"
        '';

        incr = toString cfg.brightnessIncrement;
      in
      {
        "brightness-up".body = brightnessChange { change = "${incr}%+"; };
        "brightness-down".body = brightnessChange { change = "${incr}%-"; };
      };

    # swayidle knows when the session went quiet but nothing about the power
    # source, so the AC check rides along in the command it runs.
    services.swayidle.timeouts = optional (cfg.suspendOnBatteryIdleMinutes != null) {
      timeout = cfg.suspendOnBatteryIdleMinutes * 60;

      command = toString (
        pkgs.writeShellScript "suspend-if-on-battery" ''
          mains_offline=false

          for supply in /sys/class/power_supply/*; do
            [ -r "$supply/type" ] && [ -r "$supply/online" ] || continue
            read -r type < "$supply/type"
            [ "$type" = Mains ] || continue
            read -r online < "$supply/online"

            # Any live supply keeps us up -- a dock and a barrel jack can both
            # show up here, and either one being in means wall power
            if [ "$online" = 1 ]; then
              echo "On wall power, staying awake"
              exit 0
            fi

            mains_offline=true
          done

          # Suspending needs positive proof of battery, so a kernel that names
          # its supplies differently leaves the machine up rather than risking
          # a suspend on wall power
          if [ "$mains_offline" != true ]; then
            echo "No wall power supply to read, staying awake"
            exit 0
          fi

          echo "Idle on battery, suspending"
          exec ${pkgs.systemd}/bin/systemctl suspend
        ''
      );
    };

    home.packages = with pkgs; [ brightnessctl ];
  };
}
