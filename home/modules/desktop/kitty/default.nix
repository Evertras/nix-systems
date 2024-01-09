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

    shell = mkOption {
      description = "Which shell to use, defaults to user's configured default";
      type = types.str;
      default = ".";
    };
  };

  config = mkIf cfg.enable {
    evertras.home.shell.funcs = {
      "kitty-reload".body = "kill -SIGUSR1 $(pgrep kitty)";
      "kitty-theme".body = if cfg.allowThemeOverrides then ''
        kitten theme --reload-in=all --config-file-name theme.conf
        sleep 1 && kitty-reload
      '' else
        "echo 'Kitty theme overrides are disabled'";

      /* # Keeping for reference but not actually using it...
         "retheme".body = ''
               searchterm="$@"
               if [ -z "''${searchterm}" ]; then
                 searchterm=mountain
               fi

               if ! type schemer2 &> /dev/null; then
                 mkdir -p ~/bin
                 GOBIN=~/bin/schemer2 go install github.com/thefryscorer/schemer2@latest
               fi

               echo "Retheming to ''${searchterm}"
               styli.sh -s "''${searchterm}"
               colors=$(schemer2 -format img::colors -in ~/.cache/styli.sh/wallpaper.jpg)
               IFS=$'\n'
               for color in ''${colors}; do
                 # Hijacked from show-color above
                 perl -e 'foreach $a(@ARGV){print "\e[48:2::".join(":",unpack("C*",pack("H*",$a)))."m \e[49m"};' "''${color:1}"
               done
               schemer2 -format img::kitty -in ~/.cache/styli.sh/wallpaper.jpg > ~/.config/kitty/theme.conf
               kill -SIGUSR1 $(pgrep kitty)
             }
      */
    };

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

        # Adjustments to the theme controlled by our commands
        include mode-adjustments.conf

        # Overriding things in a pinch
        include override.conf
      '';

      settings = {
        background_opacity =
          if cfg.opacity == null then theme.kittyOpacity else cfg.opacity;
        # No blinking
        cursor_blink_interval = 0;
        cursor = theme.colors.primary;
        cursor_shape = "block";
        enable_audio_bell = "no";
        # Don't change to bar when typing
        shell_integration = "no-cursor";
        # Smarter copying without trailing newlines/whitespace
        strip_trailing_spaces = "smart";

        url_style = "dashed";
        underline_hyperlinks = "always";

        shell = cfg.shell;

        # Override selection to look nicer
        selection_foreground = theme.colors.background;
        selection_background = theme.colors.primary;
      };
    };
  };
}
