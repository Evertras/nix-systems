{ config, lib, pkgs, ... }:

with lib;
let cfg = config.evertras.home.desktop;
in {
  imports = [ ./dmenu ./i3 ./kitty ./gtktheme ./notifications ];

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
      # Clipboard
      xclip

      # Window management utilities
      # https://www.semicomplete.com/projects/xdotool/
      xdotool

      # Browser
      librewolf

      # Wallpaper changer
      stylish

      # Quick image manipulation with 'convert'
      imagemagick

      # Image viewing
      feh

      # Screenshot taker and more
      # https://github.com/naelstrof/maim#examples
      maim

      # Notes
      obsidian
    ];

    evertras.home.desktop = mkIf cfg.enable {
      dmenu.enable = cfg.wm == "i3";
      gtktheme.enable = true;
      i3 = {
        enable = cfg.wm == "i3";
        kbLayout = mkDefault cfg.kbLayout;
      };
      kitty.enable = cfg.terminal == "kitty";
      notifications.enable = true;
    };
  };
}
