{ config, lib, ... }:
with lib;
let
  cfg = config.evertras.home.desktop.bars.waybar;
  theme = config.evertras.themes.selected;
  palette = (import ../../../../../shared/themes/palette-catppuccin.nix).Frappe;
in
{
  options.evertras.home.desktop.bars.waybar = {
    enable = mkEnableOption "Enable Waybar";

    outputs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "eDP-1" ];
      description = ''
        Outputs to show the bar on, matched by connector name or monitor
        description. An empty list shows the bar on every output.
      '';
    };

    # Only which modules appear, and in what order.  Each module's own
    # settings stay in this file; other modules can add their own definitions
    # by merging into programs.waybar.settings.mainBar, so any string is
    # allowed here rather than a fixed enum.
    modules =
      let
        mkModulesOption =
          position: default:
          mkOption {
            type = types.listOf types.str;
            inherit default;
            description = ''
              Modules to show on the ${position} of the bar, in order. A module
              listed here must have a definition, either in the waybar module
              itself or merged in via programs.waybar.settings.mainBar.
            '';
          };
      in
      {
        left = mkModulesOption "left" [
          "battery"
          "keyboard-state"
          "niri/language"
          "network"
          "custom/vpn"
          "niri/workspaces"
        ];

        center = mkModulesOption "center" [ ];

        right = mkModulesOption "right" [
          "pulseaudio"
          "bluetooth"
          "backlight"
          "clock"
        ];
      };

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
        # Omitting `output` entirely is what tells waybar to draw the bar on
        # every monitor, so only set it when outputs are actually pinned
        mainBar = optionalAttrs (cfg.outputs != [ ]) { output = cfg.outputs; } // {
          modules-left = cfg.modules.left;
          modules-center = cfg.modules.center;
          modules-right = cfg.modules.right;

          "niri/workspaces" = {
            format = "{value}";
          };

          "niri/language" = {
            format-ja = "JP";
            format-en = "EN";
          };

          "battery" = {
            bat = cfg.battery.name;
            interval = 60;
            states = {
              "low" = 30;
            };
            format = "{icon} {capacity}%";
            format-icons = [
              ""
              ""
              ""
              ""
              ""
            ];
            max-length = 25;
          };

          "backlight" = {
            format = "{percent} {icon}";
            format-icons = [
              "󱩎"
              "󱩏"
              "󱩐"
              "󱩑"
              "󱩒"
              "󱩓"
              "󱩔"
              "󱩕"
              "󱩖"
              "󰛨"
            ];
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

          "bluetooth" = {
            on-click = "headphones-toggle";
          };

          "pulseaudio" = {
            format = "{volume} 󰓃 ";
            format-bluetooth = "{volume} 󰋋 ";
            format-muted = "{volume}  ";
            max-volume = 40;
            on-click = "volume-mute-toggle";
          };

          /*
            For some fun later
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
