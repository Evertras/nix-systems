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
    in {
      "brightness-up".body = brightnessChange { change = "${incr}%+"; };
      "brightness-down".body = brightnessChange { change = "${incr}%-"; };
    };

    home.packages = with pkgs; [ brightnessctl ];
  };
}

