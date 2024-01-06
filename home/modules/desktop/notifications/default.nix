{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.desktop.notifications;
  theme = config.evertras.themes.selected;
in {
  options.evertras.home.desktop.notifications = {
    enable = mkEnableOption "notifications";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [
        # (Future investigation: https://github.com/Sweets/tiramisu)
        libnotify
      ];

    services.dunst = {
      enable = true;
      iconTheme = {
        name = theme.iconTheme.name;
        package = theme.iconTheme.package;
      };

      settings = {
        global = {
          corner_radius = 10;
          font = theme.fonts.desktop.name;
          frame_color = theme.colors.background;
        };

        urgency_normal = {
          background = theme.colors.primary;
          foreground = theme.colors.background;
          highlight = theme.colors.background;
          timeout = 10;
        };

        urgency_low = {
          background = theme.colors.primary;
          foreground = theme.colors.background;
          highlight = theme.colors.background;
          timeout = 10;
        };

        urgency_critical = {
          background = theme.colors.urgent;
          foreground = theme.colors.background;
          highlight = theme.colors.background;
          timeout = 10;
        };
      };
    };
  };
}
