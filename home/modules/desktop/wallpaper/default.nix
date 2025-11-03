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

    evertras.home.shell.funcs = mkIf cfg.enable {
      wallpaper-laptop.body = ''
        swww img -o ${cfg.outputs.laptop} "$1"
      '';

      wallpaper-laptop-random.body = ''
        swww img -o ${cfg.outputs.laptop} "$(random-file ${cfg.randomWallpapersDir})"
      '';

      wallpaper-external.body = ''
        swww img -o ${cfg.outputs.external} "$1"
      '';

      wallpaper-external-random.body = ''
        swww img -o ${cfg.outputs.external} "$(random-file ${cfg.randomWallpapersDir})"
      '';

      wallpaper-external-black.body = ''
        swww clear -o ${cfg.outputs.external} 000000
      '';
    };
  };
}
