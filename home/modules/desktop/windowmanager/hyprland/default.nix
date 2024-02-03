{ config, everlib, lib, pkgs, ... }:
with lib;
with everlib;
let
  cfg = config.evertras.home.desktop.windowmanager.hyprland;
  theme = config.evertras.themes.selected;
in {
  imports = [ ./waybar.nix ];

  options.evertras.home.desktop.windowmanager.hyprland = {
    enable = mkEnableOption "Enable Hyprland";

    browser = mkOption {
      type = types.str;
      default = "librewolf";
      description = "The browser command to use";
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
    evertras.home.desktop.windowmanager.hyprland.waybar.enable = true;

    wayland.windowManager.hyprland = {
      enable = true;
      enableNvidiaPatches = true;

      extraConfig = ''
        exec-once ${pkgs.waybar}/bin/waybar
      '';

      settings = {
        # https://wiki.hyprland.org/Configuring/Variables/
        "$mod" = "SUPER";

        bind = let
        in [
          "$mod, Q, killactive"
          "$mod SHIFT, Q, exit"

          # Application shortcuts
          "$mod, R, exec, ${cfg.browser}"
          "$mod, space, exec, ${cfg.terminal}"
          "$mod, P, exec, ${
            import ./toficmd.nix {
              inherit theme lib;
              type = "dmenu";
            }
          }"

          # Resize
          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"

          # Navigate
          "$mod, J, movefocus, d"
          "$mod, K, movefocus, u"

          # Master layout
          "$mod, return, layoutmsg, swapwithmaster"
          "$mod SHIFT, return, layoutmsg, orientationcycle left top"
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
          no_gaps_when_only = 1;
        };

        misc.force_default_wallpaper = 0;
      };
    };

    home.packages = with pkgs; [ hyprpaper tofi ];
  };
}
