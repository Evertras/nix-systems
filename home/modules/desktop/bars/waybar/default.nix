{ config, lib, ... }:
with lib;
let
  cfg = config.evertras.home.desktop.bars.waybar;
  theme = config.evertras.themes.selected;
  palette = (import ../../../../../shared/themes/palette-catppuccin.nix).Frappe;
in {
  options.evertras.home.desktop.bars.waybar = {
    enable = mkEnableOption "Enable Waybar";

    monitorNetworkInterface = mkOption {
      type = types.str;
      default = "wlo1";
      description = "The network interface to monitor for network status";
    };

    style = mkOption {
      type = types.str;
      default = "bubbles";
      description = "The style to use in the styles subdir";
    };

    battery = {
      name = mkOption {
        type = types.str;
        default = "BAT1";
        description = "Name of the battery, found in /sys/class/power_supply";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;

      settings = {
        mainBar = {
          # Unhardcode this later
          output = [ "eDP-1" ];
          modules-left = [
            "battery"
            "keyboard-state"
            "network"
            "custom/vpn"
            "hyprland/workspaces"
            "niri/workspaces"
          ];
          modules-center = [ "hyprland/window" ];
          modules-right = [ "pulseaudio" "bluetooth" "backlight" "clock" ];

          "hyprland/workspaces" = {
            format = "{name}";
            sort-by = "number";
          };

          "hyprland/window" = { format = "{}"; };

          "niri/workspaces" = { format = "{value}"; };

          "battery" = {
            bat = cfg.battery.name;
            interval = 60;
            states = { "low" = 30; };
            format = "{icon} {capacity}%";
            format-icons = [ "" "" "" "" "" ];
            max-length = 25;
          };

          "backlight" = {
            format = "{percent} {icon}";
            format-icons = [ "󱩎" "󱩏" "󱩐" "󱩑" "󱩒" "󱩓" "󱩔" "󱩕" "󱩖" "󰛨" ];
          };

          # Show date and time
          "clock" = {
            format = "{:%a %b %d %H:%M}";
            interval = 60;
            max-length = 50;
          };

          "keyboard-state" = {
            numlock = true;

            format.numlock = "{icon}";

            format-icons = {
              locked = "";
              unlocked = "";
            };
          };

          "network" = {
            interface = cfg.monitorNetworkInterface;
            format = "{ifname}";
            format-wifi = "  {essid} ({signalStrength}%)";
            format-ethernet = "󰊗 {ipaddr}/{cidr}";
            format-disconnected = "  None";
            tooltip-format = "󰊗 {ifname} via {gwaddr}";
            tooltip-format-wifi = "  {essid} ({signalStrength}%)";
            tooltip-format-ethernet = " {ifname}";
            tooltip-format-disconnected = "Disconnected";
            max-length = 50;
          };

          "bluetooth" = { on-click = "headphones-toggle"; };

          "pulseaudio" = {
            format = "{volume} 󰓃 ";
            format-bluetooth = "{volume} 󰋋 ";
            format-muted = "{volume}  ";
            max-volume = 40;
            on-click = "volume-mute-toggle";
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

      style = import ./styles/${cfg.style}.nix { inherit theme palette; };

      systemd.enable = true;
    };
  };
}
