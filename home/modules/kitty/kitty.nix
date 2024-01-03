{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.kitty;
in {
  options.evertras.home.kitty = {
    enable = mkEnableOption "kitty";
  };

  config = mkIf cfg.enable {
    programs = {
      kitty = {
        enable = true;

        font = {
          name = "Hasklug Nerd Font Mono";
          size = 14;
          package = pkgs.nerdfonts;
        };

        extraConfig = ''
          # I like changing the theme a lot on a whim, this
          # file is created/modified by the bash function kitty-theme
          include theme.conf

          # Overriding things in a pinch, such as demo font size switch
          include override.conf
        '';

        settings = {
          background_opacity = "0.8";
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
  };
}
