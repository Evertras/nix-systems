{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.desktop.wallpaper;
in {
  options.evertras.home.desktop.wallpaper = {
    # For now just swww, but add others in this subdir later if we want
    enable = mkEnableOption "Enable wallpaper manager via swww";

    outputs = {
      laptop = mkOption {
        type = types.str;
        default = "eDP-1";
      };

      external = mkOption {
        type = types.str;
        default = "DP-3";
      };
    };

    randomWallpapersDir = mkOption {
      type = types.str;
      default = "~/.evertras/wallpapers/";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ unstable.swww ];

    systemd.user = let rotateServiceName = "evertras-wallpaper-rotate";
    in {
      timers.wallpaper-rotate = {
        Unit.Description = "Wallpaper rotator";

        Timer = {
          OnBootSec = "5min";
          OnUnitActiveSec = "5min";
          Unit = "${rotateServiceName}.service";
        };

        Install.WantedBy = [ "timers.target" ];
      };

      services.${rotateServiceName} = {
        Unit.Description = "Rotate wallpapers";

        Service = {
          Type = "oneshot";
          # Is there a better way to do this?
          ExecStart =
            "${config.home.homeDirectory}/.nix-profile/bin/wallpaper-external-random";
        };
      };
    };

    evertras.home.shell.funcs = let
      checkOutput = output: ''
        if ! swww query | grep '${output}'; then
          echo "Output ${output} not connected."
          exit 0;
        fi
      '';

      mkSwitch = output: ''
        ${checkOutput output}
        swww img -o ${output} "$1"
      '';

      mkRandom = output: ''
        ${checkOutput output}
        swww img -o ${output} "$(random-file ${cfg.randomWallpapersDir})"
      '';

      mkClear = output: ''
        ${checkOutput output}
        swww clear -o ${output} 000000
      '';
    in mkIf cfg.enable {
      wallpaper-laptop.body = mkSwitch cfg.outputs.laptop;
      wallpaper-laptop-random.body = mkRandom cfg.outputs.laptop;
      wallpaper-external.body = mkSwitch cfg.outputs.external;
      wallpaper-external-random.body = mkRandom cfg.outputs.external;
      wallpaper-external-black.body = mkClear cfg.outputs.external;
    };
  };
}
