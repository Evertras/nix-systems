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
        default = "HDMI-A-1";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ swww ];

    evertras.home.shell.funcs = mkIf cfg.enable {
      wallpaper-laptop.body = ''
        swww img -o ${cfg.outputs.laptop} "$1"
      '';

      wallpaper-external.body = ''
        swww img -o ${cfg.outputs.external} "$1"
      '';
    };
  };
}
