{ config, lib, ... }:
with lib;
let
  cfg = config.evertras.home.desktop.display;
in
{
  options.evertras.home.desktop.display = {
    sleep = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable monitor sleep settings.  On by default so that an OLED panel
          never sits there burning in because a machine forgot to opt in.
        '';
      };

      standbyMinutes = mkOption {
        type = types.int;
        default = 10;
        description = "Idle minutes before the monitor blanks/standbys";
      };

      suspendMinutes = mkOption {
        type = types.int;
        default = 60;
        description = "Idle minutes before the monitor suspends (X11 only)";
      };

      offMinutes = mkOption {
        type = types.int;
        default = 180;
        description = "Idle minutes before the monitor turns off (X11 only)";
      };
    };
  };

  config =
    let
      # Monitor sleep settings, configured in minutes but xset wants seconds
      # man xset -> "The first value given is for the ‘standby' mode, the second is for the ‘suspend' mode, and the third is for the ‘off' mode."
      # So by default, standby after 10 minutes, then suspend after an hour, then turn off after 3 hours
      dpmsParams = map (minutes: toString (minutes * 60)) [
        cfg.sleep.standbyMinutes
        cfg.sleep.suspendMinutes
        cfg.sleep.offMinutes
      ];
      dpms = if cfg.sleep.enable then [ "xset dpms ${concatStringsSep " " dpmsParams}" ] else [ ];
    in
    {
      evertras.home.desktop.windowmanager = {
        i3.startupPostCommands = dpms;
        dwm.autostartCmds = dpms;
      };

      # TODO: Run this for hyprland somehow
    };
}
