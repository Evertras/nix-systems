{ config, lib, pkgs, ... }:

with lib;
let cfg = config.evertras.home.desktop;
in {
  imports = [ ./i3 ./kitty ./gtktheme ];

  options.evertras.home.desktop = {
    enable = mkEnableOption "desktop";

    terminal = mkOption {
      type = types.str;
      default = "kitty";
    };

    wm = mkOption {
      type = types.str;
      default = "i3";
    };

    kbLayout = mkOption {
      type = types.str;
      default = "us";
    };
  };

  config = {
    home.packages = with pkgs; [
      # Browser
      librewolf

      # Wallpapers
      feh
      stylish

      # Quick image manipulation with 'convert'
      imagemagick
    ];

    evertras.home.desktop = mkIf cfg.enable {
      i3 = {
        enable = cfg.wm == "i3";
        kbLayout = mkDefault cfg.kbLayout;
      };
      kitty.enable = cfg.terminal == "kitty";

      gtktheme.enable = true;
    };
  };
}
