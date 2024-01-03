{ config, lib, ... }:
with lib;
let
  cfg = config.evertras.home.i3;
  theme = config.evertras.themes.selected;
in {
  imports = [ ../../../themes/select.nix ];

  options.evertras.home.i3 = {
    enable = mkEnableOption "i3 desktop";

    kbLayout = mkOption {
      type = types.str;
      default = "us";
    };

    extraSessionCommands = mkOption {
      type = types.str;
      default = "";
    };

    xrandrExec = mkOption {
      type = types.str;
      default = "";
    };

    startupWallpaperTerm = mkOption {
      type = types.str;
      default = "mountain";
    };
  };

  config = mkIf cfg.enable {
    xsession.windowManager.i3 = {
      enable = true;

      config = let
        fonts = {
          names = [ "CaskaydiaCove Nerd Font" ];
          size = 14.0;
        };
      in {
        modifier = "Mod4";

        terminal = "kitty";

        defaultWorkspace = "workspace number 1";

        inherit fonts;

        window = {
          border = 2;
          hideEdgeBorders = "both";
          titlebar = false;
        };

        startup = [
          {
            command = if cfg.xrandrExec == "" then "true" else cfg.xrandrExec;
            notification = false;
          }
          {
            command = "setxkbmap -layout ${cfg.kbLayout}";
            notification = false;
          }
          {
            # Need a sleep to make xrandr take effect, not great... find better way later
            command = "sleep 1s && styli.sh -s '${cfg.startupWallpaperTerm}'";
            notification = false;
          }
        ];

        colors = let
          mkScheme = border: {
            inherit border;
            background = theme.colors.background;
            childBorder = border;
            indicator = theme.colors.urgent;
            text = theme.colors.text;
          };
        in {
          # "Focused" = current monitor
          focused = mkScheme theme.colors.highlight;
          focusedInactive = mkScheme theme.colors.primary;
          unfocused = mkScheme theme.colors.background;
        };

        bars = [{
          id = "main";

          # "Focused" = current monitor
          colors = {
            # Bar in general
            separator = theme.colors.text;
            statusline = theme.colors.text;
            focusedStatusline = theme.colors.text;
            focusedBackground = theme.colors.background;
            background = theme.colors.background;

            # Currently active workspace we're doing stuff in right now
            focusedWorkspace = {
              background = theme.colors.primary;
              border = theme.colors.primary;
              text = theme.colors.background;
            };

            # Visible on another monitor, but not the thing we're in right now
            activeWorkspace = {
              background = theme.colors.background;
              border = theme.colors.primary;
              text = theme.colors.background;
            };

            # Not visible, regardless of monitor
            inactiveWorkspace = {
              background = theme.colors.background;
              border = theme.colors.primary;
              text = theme.colors.text;
            };

            # Something on fire (like opening a link in an inactive workspace)
            urgentWorkspace = {
              background = theme.colors.urgent;
              border = theme.colors.urgent;
              text = theme.colors.text;
            };
          };

          inherit fonts;

          extraConfig = ''
            separator_symbol " | "
          '';

          statusCommand = "i3status";
          trayOutput = "none";
        }];
      };
    };

    programs.i3status = {
      enable = true;
      enableDefault = false;

      general = {
        output_format = "i3bar";
        colors = true;
        color_good = theme.colors.highlight;
        color_bad = theme.colors.urgent;
        interval = 5;
      };

      modules = {
        "load" = {
          position = 1;
          settings = { format = "%5min %15min"; };
        };

        "memory" = {
          position = 2;
          settings = { format = "Mem: %percentage_used used (%free free)"; };
        };

        "ethernet eno1" = {
          position = 3;
          settings = {
            format_up = "%ip";
            format_down = "NET DOWN";
          };
        };

        "tztime UTC" = {
          position = 4;
          settings = { format = "%m-%d %H:%M:%S UTC"; };
        };

        "tztime local" = {
          position = 5;
          settings = { format = "%Y-%m-%d %H:%M:%S %Z "; };
        };
      };
    };
  };
}
