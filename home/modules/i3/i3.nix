{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.i3;
  # https://coolors.co/ef6f6c-2e394d-dcf9eb-59c9a5-7a907c
  colors = {
    primary = "#59C9A5";
    highlight = "#A7F1CD";
    background = "#2e394d";
    text = "#DCF9EB";
    urgent = "#EF6F6C";
  };
in {
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

        colors = {
          focused = {
            background = colors.background;
            border = colors.primary;
            childBorder = colors.highlight;
            text = colors.text;
            indicator = colors.urgent;
          };
        };

        bars = [{
          id = "main";

          # "Focused" = current monitor, otherwise just background
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
  };
}
