{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.laptop;
in {
  options.evertras.home.laptop = {
    enable = mkEnableOption "Enable laptop configuration";

    brightnessIncrement = mkOption {
      type = types.int;
      default = 10;
      description = "Brightness percentage increment for brightness changes";
    };
  };

  config = mkIf cfg.enable {
    evertras.home.shell.funcs = let
      brightnessChange = { change }: ''
        level=$(brightnessctl -m set "${change}" | awk -F, '{gsub(/%$/, "", $4); print $4}')

        notify-send "Brightness $level%" \
          -i brightnesssettings \
          -t 2000 \
          -h string:synchronous:screenbrightness \
          -h "int:value:$level"
      '';

      incr = toString cfg.brightnessIncrement;
    in {
      "brightness-up".body = brightnessChange { change = "${incr}%+"; };
      "brightness-down".body = brightnessChange { change = "${incr}%-"; };
    };
  };
}

