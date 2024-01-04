{ config, lib, pkgs, ... }:

with lib;
let cfg = config.evertras.home.desktop;
in {
  imports = [ ./i3 ./kitty ./theming ];

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
      i3.enable = cfg.wm == "i3";
      kitty.enable = cfg.terminal == "kitty";

      theming.enable = true;
    };
  };
}
