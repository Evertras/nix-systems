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
            modules-center = [ "hyprland/window" ];
            modules-right = [ "network" "bluetooth" "battery" "clock" ];

            "hyprland/workspaces" = {
              format = "{name}";
              sort-by = "number";
            };

            "hyprland/window" = { format = "{}"; };

            "battery" = {
              # /sys/class/power_supply
              "bat" = "BAT1";
              "interval" = 60;
              "states" = { "low" = 30; };
              "format" = "{icon} {capacity}%";
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
            border-radius: 0.5em;
            min-height: 0;
          }

          window#waybar {
            background: ${theme.colors.background};
            color: ${theme.colors.text};
            font-family: ${theme.fonts.main.name}, Helvetica, Arial, sans-serif;
            font-size: 18px;
          }

          #battery {
            ${layout}
            color: ${palette.Sapphire};
            background-color: ${theme.colors.background};
            ${mkBorder palette.Sapphire};
          }

          #battery.low {
            color: ${theme.colors.background};
            background-color: ${theme.colors.urgent};
            border-color: ${theme.colors.urgent};
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
            color: ${palette.Lavender};
            background-color: ${theme.colors.background};
            ${mkBorder palette.Lavender};
          }

          #window {
            color: ${theme.colors.contrast};
          }

          #workspaces {
            margin: 2px;
          }

          #workspaces button {
            margin: 0 0.2em;
            padding-left: 0.3em;
            padding-right: 0.3em;
            padding-top: 0.15em;
            padding-bottom: 0.1em;
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
            color: ${theme.colors.background};
            background-color: ${theme.colors.urgent};
            border-color: ${theme.colors.urgent};
          }
        '';

        systemd.enable = true;
      };
    };
  };
}
