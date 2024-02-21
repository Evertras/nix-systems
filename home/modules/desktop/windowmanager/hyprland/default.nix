# Technically a compositor and not a window manager,
# but close enough.
{ config, everlib, lib, pkgs, ... }:
with lib;
with everlib;
let
  cfg = config.evertras.home.desktop.windowmanager.hyprland;
  theme = config.evertras.themes.selected;
in {
  imports = [ ./pyprland.nix ./waybar.nix ];

  options.evertras.home.desktop.windowmanager.hyprland = {
    enable = mkEnableOption "Enable Hyprland";

    browser = mkOption {
      type = types.str;
      default = "librewolf";
      description = "The browser command to use";
    };

    displays = mkOption {
      type = with types; listOf attrs;
      default = [ ];
      description = ''
        The displays to use.  Each display should be an attribute set with the
        following keys:

        - name: The name of the display
        - resolution: The resolution of the display
        - refreshRate: The refresh rate of the display
        - position: The position of the display (optional, defaults to 0,0)
        - scale: The scale of the display (optional, defaults to 1)
      '';
    };

    kbLayout = mkOption {
      type = types.str;
      default = "us";
      description = "The keyboard layout to use";
    };

    terminal = mkOption {
      type = types.str;
      default = "kitty -1";
      description = "The terminal command to use";
    };
  };

  config = mkIf cfg.enable {
    # Extra helpers in other files
    evertras.home.desktop.windowmanager.hyprland = {
      waybar.enable = true;
      pyprland.enable = true;
    };

    evertras.home.shell.funcs = {
      launch-app.body = let
        command = import ./toficmd.nix {
          inherit theme lib;
          type = "fullscreen";
        };
      in ''
        eval "$(${command})"
      '';
    };

    wayland.windowManager.hyprland = {
      enable = true;
      enableNvidiaPatches = true;

      # Regarding monitor configuration:
      # https://wiki.hyprland.org/Configuring/Monitors/
      extraConfig = let
        displayConfigs = builtins.map (display:
          "monitor=${display.name},${display.resolution},${
            display.position or "0x0"
          },${toString (display.scale or 1)}") cfg.displays;
      in ''
        exec-once=${pkgs.swww}/bin/swww init
        exec-once=${pkgs.pyprland}/bin/pypr
        ${strings.concatStringsSep "\n" displayConfigs}
        monitor=,preferred,auto,1
      '';

      settings = let mkColor = color: "0xff" + (strings.removePrefix "#" color);
      in {
        # https://wiki.hyprland.org/Configuring/Variables/
        "$mod" = "SUPER";

        bind = let
        in [
          # Quit and really quit
          "$mod, Q, killactive"
          "$mod SHIFT, Q, exit"

          # Application shortcuts
          "$mod, R, exec, ${cfg.browser}"
          "$mod, space, exec, ${cfg.terminal}"
          "$mod, P, exec, launch-app"
          "$mod, V, exec, ${pkgs.pyprland}/bin/pypr toggle pavucontrol"

          # Navigate
          "$mod, J, movefocus, d"
          "$mod, K, movefocus, u"
          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"

          # Media keys
          ", XF86AudioRaiseVolume, exec, volume-up"
          ", XF86AudioLowerVolume, exec, volume-down"
          ", XF86AudioLowerMute, exec, volume-mute-toggle"
          ", XF86MonBrightnessUp, exec, brightness-up"
          ", XF86MonBrightnessDown, exec, brightness-down"

          # Master layout
          "$mod, return, layoutmsg, swapwithmaster"
          "$mod SHIFT, return, layoutmsg, orientationcycle left top"

          # Fullscreen
          "$mod, F, fullscreen, 0"
        ] ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
          # Stolen/modified from https://wiki.hyprland.org/Nix/Hyprland-on-Home-Manager/
          builtins.concatLists (builtins.genList (x:
            let ws = toString (x + 1);
            in [
              "$mod, ${ws}, workspace, ${ws}"
              "$mod SHIFT, ${ws}, movetoworkspace, ${ws}"
              # Sneak in layout tweaks
              "$mod CTRL, ${ws}, layoutmsg, mfact 0.${ws}"
            ]) 9));

        decoration = { rounding = 10; };

        general = {
          gaps_out = 3;
          layout = "master";
          border_size = 2;
          "col.active_border" = mkColor theme.colors.primary;
        };

        gestures = {
          # Leaving as reference to play with later
          workspace_swipe = false;
          workspace_swipe_distance = 100;
        };

        input = {
          kb_layout = cfg.kbLayout;

          repeat_delay = 300;
        };

        master = {
          new_is_master = false;
          no_gaps_when_only = 0;
        };

        misc.force_default_wallpaper = 0;
      };
    };

    home.packages = with pkgs; [ hyprpaper tofi swww wl-clipboard ];
  };
}
