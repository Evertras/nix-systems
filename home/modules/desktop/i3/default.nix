{ config, lib, ... }:
with lib;
let
  cfg = config.evertras.home.desktop.i3;
  theme = config.evertras.themes.selected;

  fontName =
    if cfg.fontName == null then theme.fonts.main.name else cfg.fontName;

  startupWallpaperTerm = if cfg.startupWallpaperTerm == null then
    theme.inspiration
  else
    cfg.startupWallpaperTerm;
in {
  options.evertras.home.desktop.i3 = {
    enable = mkEnableOption "i3 desktop";

    kbLayout = mkOption {
      type = types.str;
      default = "us";
    };

    extraStartupCommand = mkOption {
      type = types.str;
      default = "true";
    };

    monitorNetworkInterface = mkOption {
      type = types.str;
      default = "eno1";
    };

    monitorNetworkWireless = mkOption {
      type = types.bool;
      default = false;
    };

    xrandrExec = mkOption {
      type = types.str;
      default = "true";
    };

    startupWallpaperTerm = mkOption {
      type = with types; nullOr str;
      default = null;
    };

    fontName = mkOption {
      type = with types; nullOr str;
      default = null;
    };

    fontSize = mkOption {
      type = types.float;
      default = 16.0;
    };

    keybindOverrides = mkOption {
      type = types.attrs;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    home.file = let
      screenshotsDir = "$HOME/.evertras/screenshots";
      screenshotsLog = "/tmp/screenshot-lastlog";
    in {
      ".evertras/i3funcs/screenshot.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          mkdir -p ${screenshotsDir}
          filename=${screenshotsDir}/$(date +%Y-%m-%d-%H-%M-%S | tr A-Z a-z).png
          maim "$filename" &> ${screenshotsLog}
          if [ $? == 0 ]; then
            notify-send 'Screenshot' "$filename"
          else
            notify-send -u critical "Screenshot error" "$(cat ${screenshotsLog})"
          fi
        '';
      };
    };

    xsession.windowManager.i3 = {
      enable = true;

      config = let
        fonts = {
          names = [ fontName ];
          size = cfg.fontSize;
        };

        # Win/cmd key
        modifier = "Mod4";
      in {
        inherit modifier fonts;

        terminal = config.evertras.home.desktop.terminal;

        defaultWorkspace = "workspace number 1";

        # TODO: The default references the dmenu package, seems cleaner
        #       to reference our custom-built package somehow...
        menu = "dmenu_run -p 'run >' -fn '${theme.fonts.mono.name}'";

        window = {
          border = 2;
          hideEdgeBorders = "both";
          titlebar = false;
        };

        startup = [
          {
            command = cfg.xrandrExec;
            notification = false;
          }
          {
            command = "setxkbmap -layout ${cfg.kbLayout}";
            notification = false;
          }
          {
            # Need a sleep to make xrandr take effect, not great... find better way later
            command = "sleep 1s && styli.sh -s '${startupWallpaperTerm}'";
            notification = false;
          }
          {
            command = cfg.extraStartupCommand;
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

        # Add/override existing defaults via mkOptionDefault
        # https://github.com/nix-community/home-manager/blob/master/modules/services/window-managers/i3-sway/i3.nix
        keybindings = let
          kbBase = {
            "${modifier}+w" = "exec styli.sh -s '${theme.inspiration}'";
            "${modifier}+s" = "exec ~/.evertras/i3funcs/screenshot.sh";
          };

          cfgAudio = config.evertras.home.audio;
          kbVolume = if cfgAudio.enable then {
            XF86AudioRaiseVolume = "exec ~/.evertras/funcs/volumeUp.sh";
            XF86AudioLowerVolume = "exec ~/.evertras/funcs/volumeDown.sh";
          } else
            { };

          kbBluetooth = if (cfgAudio.headphonesMacAddress != null) then {
            "${modifier}+h" = "exec ~/.evertras/funcs/headphonesConnect.sh";
            "${modifier}+shift+h" =
              "exec ~/.evertras/funcs/headphonesDisconnect.sh";
          } else
            { };

          allOverrides = kbBase // kbVolume // kbBluetooth
            // cfg.keybindOverrides;
        in mkOptionDefault allOverrides;

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

    programs.i3status = let
      networkingModule = if cfg.monitorNetworkWireless then {
        "wireless ${cfg.monitorNetworkInterface}" = {
          position = 3;
          settings = {
            format_up = "%quality %essid %ip";
            format_down = "NO WIFI";
            format_quality = "%02d%s";
          };
        };
      } else {
        "ethernet ${cfg.monitorNetworkInterface}" = {
          position = 3;
          settings = {
            format_up = "%ip";
            format_down = "NET DOWN";
          };
        };
      };
    in {
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
          settings = { format = "%free free (%percentage_used used)"; };
        };

        "tztime UTC" = {
          position = 4;
          settings = { format = "%m-%d %H:%M:%S UTC"; };
        };

        "tztime local" = {
          position = 5;
          settings = { format = "%Y-%m-%d %H:%M:%S %Z "; };
        };
      } // networkingModule;
    };
  };
}
