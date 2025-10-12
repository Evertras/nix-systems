# Technically a compositor and not a window manager,
# but close enough.
{ config, everlib, lib, pkgs, ... }:
with lib;
with everlib;
let
  cfg = config.evertras.home.desktop.windowmanager.niri;
  cfgDesktop = config.evertras.home.desktop;
  theme = config.evertras.themes.selected;
in {
  options.evertras.home.desktop.windowmanager.niri = {
    enable = mkEnableOption "Enable Niri";

    borderWidthPixels = mkOption {
      type = types.int;
      default = 4;
      description = "Border width in pixels";
    };
  };

  config = mkIf cfg.enable {
    # TODO: Extract tofi from hyprland for launching things
    # TODO: Switch to regular after 25.11, we need updated for xwayland-satellite integration for now
    home.packages = with pkgs; [ unstable.niri unstable.xwayland-satellite ];

    home.file = {
      ".config/niri/config.kdl" =
        let borderWidthPixels = toString cfg.borderWidthPixels;
        in {
          text = ''
            // This config is in the KDL format: https://kdl.dev
            // "/-" comments out the following node.
            // Check the wiki for a full description of the configuration:
            // https://github.com/YaLTeR/niri/wiki/Configuration:-Introduction

            input {
                keyboard {
                    xkb {
                        layout "${cfgDesktop.kbLayout}"
                    }

                    repeat-delay 250
                    repeat-rate 40

                    numlock
                }

                touchpad {
                    tap
                    natural-scroll
                }

                warp-mouse-to-focus

                focus-follows-mouse max-scroll-amount="25%"
            }

            layout {
                gaps 0

                // When to center a column when changing focus, options are:
                // - "never", default behavior, focusing an off-screen column will keep at the left
                //   or right edge of the screen.
                // - "always", the focused column will always be centered.
                // - "on-overflow", focusing a column will center it if it doesn't fit
                //   together with the previously focused column.
                center-focused-column "never"

                // You can customize the widths that "switch-preset-column-width" (Mod+R) toggles between.
                preset-column-widths {
                    proportion 0.3
                    proportion 0.5
                    proportion 0.7
                }

                // You can also customize the heights that "switch-preset-window-height" (Mod+Shift+R) toggles between.
                // preset-window-heights { }

                default-column-width { proportion 0.5; }

                focus-ring {
                  off
                }

                border {
                  width ${borderWidthPixels}
                  active-color "${theme.colors.primary}"
                  inactive-color "${theme.colors.background}"
                  urgent-color "${theme.colors.urgent}"
                }

                struts {
                  top -${borderWidthPixels}
                  bottom -${borderWidthPixels}
                  left -${borderWidthPixels}
                  right -${borderWidthPixels}
                }
            }

            spawn-at-startup "waybar"
            spawn-at-startup "swww-daemon"

            environment {
              DISPLAY ":0"
            }

            cursor {
              xcursor-theme "${theme.cursorTheme.name}"
              xcursor-size 48
            }

            hotkey-overlay {
                skip-at-startup
            }

            // Uncomment this line to ask the clients to omit their client-side decorations if possible.
            // If the client will specifically ask for CSD, the request will be honored.
            // Additionally, clients will be informed that they are tiled, removing some client-side rounded corners.
            // This option will also fix border/focus ring drawing behind some semitransparent windows.
            // After enabling or disabling this, you need to restart the apps for this to take effect.
            // prefer-no-csd

            screenshot-path "~/.evertras/screenshots/%Y-%m-%d %H-%M-%S.png"

            // Work around WezTerm's initial configure bug
            // by setting an empty default-column-width.
            window-rule {
                // This regular expression is intentionally made as specific as possible,
                // since this is the default config, and we want no false positives.
                // You can get away with just app-id="wezterm" if you want.
                match app-id=r#"^org\.wezfurlong\.wezterm$"#
                default-column-width {}
            }

            // Open the Firefox picture-in-picture player as floating by default.
            window-rule {
                // This app-id regular expression will work for both:
                // - host Firefox (app-id is "firefox")
                // - Flatpak Firefox (app-id is "org.mozilla.firefox")
                match app-id=r#"firefox$"# title="^Picture-in-Picture$"
                open-floating true
            }

            // Example: block out two password managers from screen capture.
            // (This example rule is commented out with a "/-" in front.)
            /-window-rule {
                match app-id=r#"^org\.keepassxc\.KeePassXC$"#
                match app-id=r#"^org\.gnome\.World\.Secrets$"#

                block-out-from "screen-capture"

                // Use this instead if you want them visible on third-party screenshot tools.
                // block-out-from "screencast"
            }

            window-rule {
                geometry-corner-radius 0
                clip-to-geometry true
            }

            binds {
                // Keys consist of modifiers separated by + signs, followed by an XKB key name
                // in the end. To find an XKB name for a particular key, you may use a program
                // like wev.
                //
                // "Mod" is a special modifier equal to Super when running on a TTY, and to Alt
                // when running as a winit window.
                //
                // Most actions that you can bind here can also be invoked programmatically with
                // `niri msg action do-something`.

                // Mod-Shift-/, which is usually the same as Mod-?,
                // shows a list of important hotkeys.
                Mod+Shift+Slash { show-hotkey-overlay; }

                // Suggested binds for running programs: terminal, app launcher, screen locker.
                Mod+Space hotkey-overlay-title="Open a Terminal: kitty" { spawn "kitty" "-1"; }
                Mod+P hotkey-overlay-title="Run an Application: launch-app" { spawn "launch-app"; }
                // Super+Alt+L hotkey-overlay-title="Lock the Screen: swaylock" { spawn "swaylock"; }

                XF86AudioRaiseVolume allow-when-locked=true { spawn "volume-up"; }
                XF86AudioLowerVolume allow-when-locked=true { spawn "volume-down"; }
                XF86AudioMute        allow-when-locked=true { spawn "volume-mute-toggle"; }

                // Open/close the Overview: a zoomed-out view of workspaces and windows.
                // You can also move the mouse into the top-left hot corner,
                // or do a four-finger swipe up on a touchpad.
                Mod+O repeat=false { toggle-overview; }

                Mod+Q { close-window; }

                Mod+Left  { focus-column-left; }
                Mod+Down  { focus-window-down; }
                Mod+Up    { focus-window-up; }
                Mod+Right { focus-column-right; }
                Mod+H     { focus-column-left; }
                // Only jump between workspaces on up/down
                Mod+J     { focus-window-or-workspace-down; }
                Mod+K     { focus-window-or-workspace-up; }
                Mod+L     { focus-column-right; }

                Mod+Ctrl+Left  { move-column-left; }
                Mod+Ctrl+Down  { move-window-down; }
                Mod+Ctrl+Up    { move-window-up; }
                Mod+Ctrl+Right { move-column-right; }
                Mod+Ctrl+H     { move-column-left; }
                Mod+Ctrl+J     { move-window-down; }
                Mod+Ctrl+K     { move-window-up; }
                Mod+Ctrl+L     { move-column-right; }

                Mod+Home { focus-column-first; }
                Mod+End  { focus-column-last; }
                Mod+Ctrl+Home { move-column-to-first; }
                Mod+Ctrl+End  { move-column-to-last; }

                Mod+Shift+Left  { focus-monitor-left; }
                Mod+Shift+Down  { focus-monitor-down; }
                Mod+Shift+Up    { focus-monitor-up; }
                Mod+Shift+Right { focus-monitor-right; }
                Mod+Shift+H     { focus-monitor-left; }
                Mod+Shift+J     { focus-monitor-down; }
                Mod+Shift+K     { focus-monitor-up; }
                Mod+Shift+L     { focus-monitor-right; }

                Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; }
                Mod+Shift+Ctrl+Down  { move-column-to-monitor-down; }
                Mod+Shift+Ctrl+Up    { move-column-to-monitor-up; }
                Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }
                Mod+Shift+Ctrl+H     { move-column-to-monitor-left; }
                Mod+Shift+Ctrl+J     { move-column-to-monitor-down; }
                Mod+Shift+Ctrl+K     { move-column-to-monitor-up; }
                Mod+Shift+Ctrl+L     { move-column-to-monitor-right; }

                // Alternatively, there are commands to move just a single window:
                // Mod+Shift+Ctrl+Left  { move-window-to-monitor-left; }
                // ...

                // And you can also move a whole workspace to another monitor:
                // Mod+Shift+Ctrl+Left  { move-workspace-to-monitor-left; }
                // ...

                Mod+Page_Down      { focus-workspace-down; }
                Mod+Page_Up        { focus-workspace-up; }
                Mod+U              { focus-workspace-down; }
                Mod+I              { focus-workspace-up; }
                Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
                Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }
                Mod+Ctrl+U         { move-column-to-workspace-down; }
                Mod+Ctrl+I         { move-column-to-workspace-up; }

                Mod+Shift+Page_Down { move-workspace-down; }
                Mod+Shift+Page_Up   { move-workspace-up; }
                Mod+Shift+U         { move-workspace-down; }
                Mod+Shift+I         { move-workspace-up; }

                // You can bind mouse wheel scroll ticks using the following syntax.
                // These binds will change direction based on the natural-scroll setting.
                //
                // To avoid scrolling through workspaces really fast, you can use
                // the cooldown-ms property. The bind will be rate-limited to this value.
                // You can set a cooldown on any bind, but it's most useful for the wheel.
                Mod+WheelScrollDown      cooldown-ms=150 { focus-workspace-down; }
                Mod+WheelScrollUp        cooldown-ms=150 { focus-workspace-up; }
                Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
                Mod+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; }

                Mod+WheelScrollRight      { focus-column-right; }
                Mod+WheelScrollLeft       { focus-column-left; }
                Mod+Ctrl+WheelScrollRight { move-column-right; }
                Mod+Ctrl+WheelScrollLeft  { move-column-left; }

                // Usually scrolling up and down with Shift in applications results in
                // horizontal scrolling; these binds replicate that.
                Mod+Shift+WheelScrollDown      { focus-column-right; }
                Mod+Shift+WheelScrollUp        { focus-column-left; }
                Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
                Mod+Ctrl+Shift+WheelScrollUp   { move-column-left; }

                // You can refer to workspaces by index. However, keep in mind that
                // niri is a dynamic workspace system, so these commands are kind of
                // "best effort". Trying to refer to a workspace index bigger than
                // the current workspace count will instead refer to the bottommost
                // (empty) workspace.
                //
                // For example, with 2 workspaces + 1 empty, indices 3, 4, 5 and so on
                // will all refer to the 3rd workspace.
                Mod+1 { focus-workspace 1; }
                Mod+2 { focus-workspace 2; }
                Mod+3 { focus-workspace 3; }
                Mod+4 { focus-workspace 4; }
                Mod+5 { focus-workspace 5; }
                Mod+6 { focus-workspace 6; }
                Mod+7 { focus-workspace 7; }
                Mod+8 { focus-workspace 8; }
                Mod+9 { focus-workspace 9; }
                Mod+Shift+1 { move-column-to-workspace 1; }
                Mod+Shift+2 { move-column-to-workspace 2; }
                Mod+Shift+3 { move-column-to-workspace 3; }
                Mod+Shift+4 { move-column-to-workspace 4; }
                Mod+Shift+5 { move-column-to-workspace 5; }
                Mod+Shift+6 { move-column-to-workspace 6; }
                Mod+Shift+7 { move-column-to-workspace 7; }
                Mod+Shift+8 { move-column-to-workspace 8; }
                Mod+Shift+9 { move-column-to-workspace 9; }

                // Alternatively, there are commands to move just a single window:
                // Mod+Ctrl+1 { move-window-to-workspace 1; }

                // Switches focus between the current and the previous workspace.
                Mod+Tab { focus-workspace-previous; }

                // The following binds move the focused window in and out of a column.
                // If the window is alone, they will consume it into the nearby column to the side.
                // If the window is already in a column, they will expel it out.
                Mod+BracketLeft  { consume-or-expel-window-left; }
                Mod+BracketRight { consume-or-expel-window-right; }

                // Consume one window from the right to the bottom of the focused column.
                Mod+Comma  { consume-window-into-column; }
                // Expel the bottom window from the focused column to the right.
                Mod+Period { expel-window-from-column; }

                Mod+R { switch-preset-column-width; }
                Mod+Shift+R { switch-preset-window-height; }
                Mod+Ctrl+R { reset-window-height; }
                Mod+F { maximize-column; }
                Mod+Shift+F { fullscreen-window; }

                // Expand the focused column to space not taken up by other fully visible columns.
                // Makes the column "fill the rest of the space".
                Mod+Ctrl+F { expand-column-to-available-width; }

                Mod+C { center-column; }

                // Center all fully visible columns on screen.
                Mod+Ctrl+C { center-visible-columns; }

                // Finer width adjustments.
                // This command can also:
                // * set width in pixels: "1000"
                // * adjust width in pixels: "-5" or "+5"
                // * set width as a percentage of screen width: "25%"
                // * adjust width as a percentage of screen width: "-10%" or "+10%"
                // Pixel sizes use logical, or scaled, pixels. I.e. on an output with scale 2.0,
                // set-column-width "100" will make the column occupy 200 physical screen pixels.
                Mod+Minus { set-column-width "-10%"; }
                Mod+Asciicircum { set-column-width "+10%"; }

                // Finer height adjustments when in column with other windows.
                Mod+Shift+Minus { set-window-height "-10%"; }
                Mod+Shift+Asciicircum { set-window-height "+10%"; }

                // Move the focused window between the floating and the tiling layout.
                Mod+V       { toggle-window-floating; }
                Mod+Shift+V { switch-focus-between-floating-and-tiling; }

                Mod+W { toggle-column-tabbed-display; }

                Ctrl+Alt+P { screenshot; }
                Print { screenshot-screen; }
                Alt+Print { screenshot-window; }

                // Applications such as remote-desktop clients and software KVM switches may
                // request that niri stops processing the keyboard shortcuts defined here
                // so they may, for example, forward the key presses as-is to a remote machine.
                // It's a good idea to bind an escape hatch to toggle the inhibitor,
                // so a buggy application can't hold your session hostage.
                //
                // The allow-inhibiting=false property can be applied to other binds as well,
                // which ensures niri always processes them, even when an inhibitor is active.
                Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }

                // The quit action will show a confirmation dialog to avoid accidental exits.
                Mod+Shift+E { quit; }
                Ctrl+Alt+Delete { quit; }

                // Powers off the monitors. To turn them back on, do any input like
                // moving the mouse or pressing any other key.
                Mod+Shift+P { power-off-monitors; }
            }
          '';
        };
    };
  };
}
