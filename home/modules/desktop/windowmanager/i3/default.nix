{ config, everlib, lib, pkgs, ... }:
with lib;
with everlib;
let
  cfg = config.evertras.home.desktop.windowmanager.i3;
  theme = config.evertras.themes.selected;

  fontName = existsOr cfg.fontName theme.fonts.main.name;

  startupWallpaperTerm = existsOr cfg.startupWallpaperTerm theme.inspiration;
in {
  options.evertras.home.desktop.windowmanager.i3 = {
    enable = mkEnableOption "i3 desktop";

    kbLayout = mkOption {
      type = types.str;
      default = "us";
    };

    startupPreCommands = mkOption {
      type = with types; listOf str;
      default = [ ];
    };

    startupPostCommands = mkOption {
      type = with types; listOf str;
      default = [ ];
    };

    monitorNetworkInterface = mkOption {
      type = types.str;
      default = "eno1";
    };

    monitorNetworkWireless = mkOption {
      type = types.bool;
      default = false;
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

    bars = mkOption {
      type = with types; listOf anything;
      default = [{
        id = "main";
        # Defaults to true
        showStatus = true;
        # Defaults to all
        outputs = [ ];
      }];
    };
  };

  config = mkIf cfg.enable {
    evertras.home.shell.funcs = {
      i3-hotkeys.body = ''
        ag '^bindsym' ~/.config/i3/config | cut -d' ' -f2- | sort -u
      '';
    };

    home.packages = with pkgs; [ i3lock-color ];

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

        menu = "dmenu_run";

        window = {
          border = 2;
          hideEdgeBorders = "both";
          titlebar = false;
        };

        startup = let
          preCommands = map (cmd: {
            command = cmd;
            notification = false;
          }) cfg.startupPreCommands;
          postCommands = map (cmd: {
            command = cmd;
            notification = false;
          }) cfg.startupPostCommands;
        in (preCommands ++ [
          {
            command = "setxkbmap -layout ${cfg.kbLayout}";
            notification = false;
          }
          {
            command =
              "while ! styli.sh -s '${startupWallpaperTerm}'; do sleep 1; done";
            notification = false;
          }
        ] ++ postCommands);

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
        # See key names with 'xmodmap -pke' or use xev, nix-shell -p as needed
        keybindings = let
          execFunc = name: "exec ~/.evertras/funcs/${name}";
          kbBase = let
            i3LockCategories =
              [ "time" "date" "layout" "verif" "wrong" "greeter" ];
            i3LockFontFlags = strings.concatStringsSep " " (map (category:
              "--${category}-font '${theme.fonts.main.name}' --${category}-size 150")
              i3LockCategories);
            # TODO: Pass in current wallpaper from stylish as an option... also maybe make
            # this its own dedicated function with easier config to maintain
            i3LockExpression =
              "i3lock-color -c '${theme.colors.background}' -e --line-uses-inside --separator-color '${theme.colors.urgent}' --ring-color '${theme.colors.primary}' --inside-color '${theme.colors.background}' --ringver-color '${theme.colors.highlight}' --insidever-color '${theme.colors.background}' --ringwrong-color '${theme.colors.urgent}' --insidewrong-color '${theme.colors.urgent}' --keyhl-color '${theme.colors.background}' --bshl-color '${theme.colors.urgent}' --verif-color '${theme.colors.text}' --wrong-color '${theme.colors.background}' --layout-color '${theme.colors.text}' --verif-text='...' --wrong-text 'nah' --noinput-text='?' ${i3LockFontFlags} --pass-volume-keys --pass-screen-keys --pass-media-keys --ring-width=100 --radius 400 &>/tmp/locklog";
          in {
            "${modifier}+Escape" = "exec ${i3LockExpression}";
            "${modifier}+w" = "exec styli.sh -s '${theme.inspiration}'";
            "${modifier}+s" = execFunc "screenshot-copy";
            "${modifier}+Shift+s" = execFunc "screenshot-save";
            "${modifier}+o" = "move workspace to output left";
            "${modifier}+p" = "move workspace to output right";
            "${modifier}+h" = "focus left";
            "${modifier}+j" = "focus down";
            "${modifier}+k" = "focus up";
            "${modifier}+l" = "focus right";
            "${modifier}+v" = "split v";
            "${modifier}+Shift+v" = "split h";
          };

          cfgAudio = config.evertras.home.audio;
          kbVolume = if cfgAudio.enable then {
            XF86AudioRaiseVolume = execFunc "volume-up";
            XF86AudioLowerVolume = execFunc "volume-down";
            XF86AudioMute = execFunc "volume-mute-toggle";
          } else
            { };

          kbBluetooth = if (cfgAudio.headphonesMacAddress != null) then {
            "${modifier}+c" = execFunc "headphones-connect";
            "${modifier}+Shift+c" = execFunc "headphones-disconnect";
          } else
            { };

          allOverrides = kbBase // kbVolume // kbBluetooth
            // cfg.keybindOverrides;
        in mkOptionDefault allOverrides;

        bars = let
          mkBarConfig = { id, showStatus ? true, outputs ? [ ] }: {
            inherit id fonts;

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
                text = theme.colors.primary;
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

            extraConfig =
              let outputStrings = map (output: "output ${output}") outputs;
              in ''
                separator_symbol " | "
                ${concatStringsSep "\n" outputStrings}
              '';

            statusCommand = mkIf showStatus "i3status";
            trayOutput = "none";
          };
        in (map mkBarConfig cfg.bars);
      };
    };

    services.picom = {
      enable = mkDefault true;

      vSync = true;
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
