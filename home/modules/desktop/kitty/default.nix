{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.desktop.kitty;
  theme = config.evertras.themes.selected;
in {
  options.evertras.home.desktop.kitty = {
    enable = mkEnableOption "kitty";

    allowThemeOverrides = mkOption {
      type = types.bool;
      default = false;
    };

    opacity = mkOption {
      type = with types; nullOr str;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;

      theme = theme.kittyTheme;

      font = {
        name = "Hasklug Nerd Font Mono";
        size = 14;
        package = pkgs.nerdfonts;
      };

      extraConfig = ''
        ${if cfg.allowThemeOverrides then ''
          # I like changing the theme a lot on a whim, this
          # file is created/modified by the bash function kitty-theme
          include theme.conf
        '' else
          ""}

        # Overriding things in a pinch, such as demo font size switch
        include override.conf
      '';

      settings = {
        background_opacity =
          if cfg.opacity == null then theme.kittyOpacity else cfg.opacity;
        # No blinking
        cursor_blink_interval = 0;
        cursor_shape = "block";
        enable_audio_bell = "no";
        # Don't change to bar when typing
        shell_integration = "no-cursor";
        strip_trailing_spaces = "smart";
      };
    };
  };
}
