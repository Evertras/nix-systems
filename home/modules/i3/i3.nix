{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.i3;
  theme = config.evertras.theme;
  colors = theme.colors;
in {
  imports = [ ../../../themes/themes.nix ];

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

        colors = let
          mkScheme = border: {
            inherit border;
            background = colors.background;
            childBorder = border;
            indicator = colors.urgent;
            text = colors.text;
          };
        in {
          # "Focused" = current monitor
          focused = mkScheme colors.highlight;
          focusedInactive = mkScheme colors.primary;
          unfocused = mkScheme colors.background;
        };

        bars = [{
          id = "main";

          # "Focused" = current monitor
          colors = {
            # Bar in general
            separator = colors.text;
            statusline = colors.text;
            focusedStatusline = colors.text;
            focusedBackground = colors.background;
            background = colors.background;

            # Currently active workspace we're doing stuff in right now
            focusedWorkspace = {
              background = colors.primary;
              border = colors.primary;
              text = colors.background;
            };

            # Visible on another monitor, but not the thing we're in right now
            activeWorkspace = {
              background = colors.background;
              border = colors.primary;
              text = colors.background;
            };

            # Not visible, regardless of monitor
            inactiveWorkspace = {
              background = colors.background;
              border = colors.primary;
              text = colors.text;
            };

            # Something on fire (like opening a link in an inactive workspace)
            urgentWorkspace = {
              background = colors.urgent;
              border = colors.urgent;
              text = colors.text;
            };
          };

          inherit fonts;

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
        color_good = colors.highlight;
        color_bad = colors.urgent;
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
