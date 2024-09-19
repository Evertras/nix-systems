{ config, everlib, lib, ... }:
with everlib;
with lib;
let
  cfg = config.evertras.home.desktop.terminals.kitty;
  theme = config.evertras.themes.selected;
  shellBin = config.evertras.home.shell.core.shellBin;
in {
  options.evertras.home.desktop.terminals.kitty = {
    enable = mkEnableOption "kitty";

    allowThemeOverrides = mkOption {
      type = types.bool;
      default = false;
    };

    fontName = mkOption {
      type = with types; nullOr str;
      default = null;
    };

    fontSize = mkOption {
      type = types.int;
      default = 14;
    };

    opacity = mkOption {
      type = with types; nullOr str;
      default = null;
    };

    shell = mkOption {
      description = "Which shell to use, defaults to user's configured default";
      type = with types; nullOr str;
      default = null;
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

    programs.kitty = let opacity = existsOr cfg.opacity theme.kittyOpacity;
    in {
      enable = true;

      theme = theme.kittyTheme;

      font = {
        name = existsOr cfg.fontName theme.fonts.terminal.name;
        size = cfg.fontSize;
        package = theme.fonts.terminal.package;
      };

      extraConfig = let fontSizeDemo = cfg.fontSize * 1.5;
      in ''
        ${if cfg.allowThemeOverrides then ''
          # I like changing the theme a lot on a whim, this
          # file is created/modified by the bash function kitty-theme
          include theme.conf
        '' else
          ""}

        # Font size adjustments
        map ctrl+shift+o change_font_size current -2.0
        map ctrl+shift+i change_font_size current +2.0
        map ctrl+shift+u change_font_size current 0

        # Demo mode
        map ctrl+shift+b combine : change_font_size current ${
          toString fontSizeDemo
        } : set_background_opacity 1.0
        map ctrl+shift+r combine : change_font_size current ${
          toString cfg.fontSize
        } : set_background_opacity ${opacity}

        # Overriding things in a pinch
        include override.conf
      '';

      settings = {
        # Background opacity
        background_opacity = opacity;
        dynamic_background_opacity = true;

        # No blinking
        cursor = theme.colors.primary;
        cursor_blink_interval = 0;
        cursor_shape = "block";

        # No bells
        enable_audio_bell = "no";

        # Don't change to bar when typing
        shell_integration = "no-cursor";

        # Smarter copying without trailing newlines/whitespace
        strip_trailing_spaces = "smart";

        # Let the cursor stay a pointer
        default_pointer_shape = "arrow";

        # Hide when typing (any negative value works)
        mouse_hide_wait = "-1.0";

        # URLs
        url_style = "dashed";
        underline_hyperlinks = "always";

        # Which shell to run
        shell = existsOr cfg.shell shellBin;

        # Override selection to look nicer
        selection_foreground = theme.colors.background;
        selection_background = theme.colors.primary;

        # Slight padding for readability
        window_padding_width = 5;
      };
    };
  };
}
