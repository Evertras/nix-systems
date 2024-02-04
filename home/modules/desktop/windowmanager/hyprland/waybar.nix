{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.desktop.windowmanager.hyprland.waybar;
  theme = config.evertras.themes.selected;
  palette = (import ../../../../../shared/themes/palette-catppuccin.nix).Frappe;
in {
  options.evertras.home.desktop.windowmanager.hyprland.waybar = {
    enable = mkEnableOption "Enable Waybar";

    monitorNetworkInterface = mkOption {
      type = types.str;
      default = "wlo1";
      description = "The network interface to monitor for network status";
    };
  };

  config = mkIf cfg.enable {
    programs = {
      waybar = {
        enable = true;

        settings = {
          mainBar = {
            modules-left = [ "hyprland/workspaces" ];
            modules-right = [ "network" "bluetooth" "battery" "clock" ];

            "hyprland/workspaces" = {
              format = "{name}";
              sort-by = "number";
            };

            "battery" = {
              # /sys/class/power_supply
              "bat" = "BAT1";
              "interval" = 60;
              "states" = { "low" = 30; };
              "format" = "{capacity}% {icon}";
              "format-icons" = [ "" "" "" "" "" ];
              "max-length" = 25;
            };

            "network" = {
              "interface" = cfg.monitorNetworkInterface;
              "format" = "{ifname}";
              "format-wifi" = " {essid} ({signalStrength}%)";
              "format-ethernet" = "󰊗 {ipaddr}/{cidr}";
              "format-disconnected" = " None";
              "tooltip-format" = "󰊗 {ifname} via {gwaddr}";
              "tooltip-format-wifi" = " {essid} ({signalStrength}%)";
              "tooltip-format-ethernet" = " {ifname}";
              "tooltip-format-disconnected" = "Disconnected";
              "max-length" = 50;
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

        style = let
          layout = ''
            padding: 0 0.5em;
            margin: 0 0.25em;
          '';
          mkBorder = color: "border-bottom: 3px solid ${color}";
        in ''
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
          }

          #battery {
            ${layout}
            color: ${theme.colors.background};
            background-color: ${palette.Sapphire};
          }

          #battery.low {
            background-color: ${theme.colors.urgent};
          }

          #bluetooth {
            ${layout}
            background-color: ${theme.colors.background};
            color: ${palette.Blue};
            ${mkBorder palette.Blue};
          }

          #bluetooth.connected {
            background-color: ${palette.Blue};
            color: ${theme.colors.background};
            border: none;
          }

          #clock {
            ${layout}
          }

          #network {
            ${layout}
            color: ${theme.colors.background};
          }

          #network.disconnected {
            background-color: ${theme.colors.urgent};
          }

          #network.wifi {
            background-color: ${palette.Lavender};
          }

          #workspaces {
            margin: 2px;
          }

          #workspaces button {
            margin: 0 2px;
            padding-left: 1px;
            padding-right: 1px;
            padding-top: 2px;
            padding-bottom: 0;
            ${mkBorder theme.colors.primary};
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
