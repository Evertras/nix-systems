{ config, lib, ... }:
with lib;
let cfg = config.evertras.home.desktop.display;
in {
  options.evertras.home.desktop.display = {
    sleep = {
      enable = mkEnableOption "Enable monitor sleep settings";

      standbySeconds = mkOption {
        type = types.int;
        default = 600;
        description = "Standby time in seconds";
      };

      suspendSeconds = mkOption {
        type = types.int;
        default = 3600;
        description = "Suspend time in seconds";
      };

      offSeconds = mkOption {
        type = types.int;
        default = 10800;
        description = "Off time in seconds";
      };
    };
  };

  config = {
    evertras.home.desktop.i3.startupPostCommands = let
      # Monitor sleep settings
      # Units in seconds
      # man xset -> "The first value given is for the ‘standby' mode, the second is for the ‘suspend' mode, and the third is for the ‘off' mode."
      # So basically, standby after 10 minutes, then suspend after an hour, then turn off after 3 hours
      dpmsParams = map toString [
        cfg.sleep.standbySeconds
        cfg.sleep.suspendSeconds
        cfg.sleep.offSeconds
      ];
      dpms = if cfg.sleep.enable then
        [ "xset dpms ${concatStringsSep " " dpmsParams}" ]
      else
        [ ];
    in dpms;
  };
}
