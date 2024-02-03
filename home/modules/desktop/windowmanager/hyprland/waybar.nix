{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.desktop.windowmanager.hyprland.waybar;
  theme = config.evertras.themes.selected;
in {
  options.evertras.home.desktop.windowmanager.hyprland.waybar = {
    enable = mkEnableOption "Enable Waybar";
  };

  config = mkIf cfg.enable {
    programs = {
      waybar = {
        enable = true;

        settings = {
          mainBar = {
            modules-left = [ "hyprland/workspaces" ];
            modules-right = [ "bluetooth" "clock" ];

            "hyprland/workspaces" = {
              format = "{name}";
              sort-by = "number";
            };

            /* For some fun later
               "custom/hello-from-waybar" = {
                 format = "hello {}";
                 max-length = 40;
                 interval = "once";
                 exec = pkgs.writeShellScript "hello-from-waybar" ''
                   echo "from within waybar"
                 '';
               };
            */
          };
        };

        style = ''
          /* NOTE: this rule overrides things
            at random, use with caution despite
            it being in the doc example...
          */
          * {
            border: none;
            border-radius: 4px;
            min-height: 0;
          }

          window#waybar {
            background: ${theme.colors.background};
            color: ${theme.colors.text};
            font-family: ${theme.fonts.main.name}, Helvetica, Arial, sans-serif;
            font-size: 12px;
            font-weight: bold;
          }

          #clock {
            padding: 0 10px;
          }

          #workspaces {
            margin: 2px;
          }

          #workspaces button {
            margin: 0 2px;
            padding: 1px 1px;
            border: 2px solid ${theme.colors.primary};
            border-radius: 0.5em;
            color: ${theme.colors.primary};
            background-color: ${theme.colors.background};
          }

          #workspaces button.empty {
          }

          #workspaces button.visible {
          }

          #workspaces button.active {
            color: ${theme.colors.background};
            background-color: ${theme.colors.primary};
          }

          #workspaces button.urgent {
            background-color: ${theme.colors.urgent};
          }
        '';

        systemd.enable = true;
      };
    };
  };
}
