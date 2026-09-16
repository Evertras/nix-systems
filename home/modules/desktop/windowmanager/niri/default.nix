# Technically a compositor and not a window manager,
# but close enough.
{
  config,
  everlib,
  lib,
  pkgs,
  ...
}:
with lib;
with everlib;
let
  cfg = config.evertras.home.desktop.windowmanager.niri;
  cfgDesktop = config.evertras.home.desktop;
  theme = config.evertras.themes.selected;
in
{
  options.evertras.home.desktop.windowmanager.niri = {
    enable = mkEnableOption "Enable Niri";

    borderWidthPixels = mkOption {
      type = types.int;
      default = 4;
      description = "Border width in pixels";
    };

    cursorSize = mkOption {
      type = types.int;
      description = "Cursor size";
    };

    terminal = mkOption {
      type = types.str;
      description = "Terminal to use";
    };

    scaleMain = mkOption {
      type = with types; either int float;
      default = 1.2;
    };

    scaleExternal = mkOption {
      type = with types; either int float;
      default = 1.2;
    };

    defaultColumns = mkOption {
      type = types.int;
      default = 2;
      description = ''
        How many columns should fit on screen, i.e. new windows open at
        1/defaultColumns of the screen width.

        This is only the starting value.  Niri has no IPC action to change
        the default column width at runtime, so the live value lives in
        ~/.config/niri/column-width.kdl, which the main config `include`s and
        which niri's config watcher reloads on write.  The niri-columns func
        rewrites that file and resizes the already-open columns to match, and
        the niri-column-cycle func reads the count back out of it to decide
        which widths Mod+R cycles the focused column through.
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      # Niri can only change the width of the *focused* column at runtime, and
      # has no action at all for the default width of new windows.  Work around
      # that by keeping the default in its own file that the main config
      # includes: niri's config watcher watches included files too, so writing
      # this file makes niri reload and pick up the new default immediately.
      #
      # It has to be a window-rule and not a `layout` node because only one
      # top-level `layout` node is allowed, and `include` only works at the top
      # level.  A window-rule with no `match` applies to every window.
      # Each side strut is negative, so the two of them widen the working area
      # that column proportions are measured against.  The struts node below and
      # niri-column-cycle both derive from this, so they cannot drift apart.
      sideStrutPixels = cfg.borderWidthPixels * 2;

      columnWidthFile = "column-width.kdl";
      columnWidthDir = "${config.xdg.configHome}/niri";
      columnWidthPath = "${columnWidthDir}/${columnWidthFile}";

      # niri-column-cycle reads the count back out of this with a regex over a
      # single line, so keep default-column-width and proportion together.
      mkColumnWidth = columns: ''
        // Generated - rewritten by the niri-columns func, do not edit by hand.
        window-rule {
            default-column-width { proportion ${toString (1.0 / columns)}; }
        }
      '';

      initialColumnWidthFile = pkgs.writeText "niri-column-width.kdl" (mkColumnWidth cfg.defaultColumns);
    in
    {
      evertras.home.desktop.bars.waybar.style = "solid";

      home.packages = with pkgs; [
        niri
        xwayland-satellite
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk

        # Other things we want
        nautilus
        wl-clipboard
      ];

      services.swayidle =
        let
          niriBin = "${pkgs.niri}/bin/niri";
          monitorsOn = "${niriBin} msg action power-on-monitors";
          monitorsOff = "${niriBin} msg action power-off-monitors";
          sleepCfg = cfgDesktop.display.sleep;
        in
        {
          enable = true;
          events = {
            # The big monitor doesn't like to turn on on its own, but it will respect this command
            after-resume = monitorsOn;
          };
          # Niri only powers monitors off or on, so standby is the only stage we use here
          timeouts = optionals sleepCfg.enable [
            {
              timeout = sleepCfg.standbyMinutes * 60;
              command = monitorsOff;
              resumeCommand = monitorsOn;
            }
          ];
        };

      home.file = {
        ".config/niri/config.kdl" =
          let
            borderWidthPixels = toString cfg.borderWidthPixels;
            doubleBorderWidthPixels = toString sideStrutPixels;

            # Hardcoded for the beast for easy hardcode switching depending on performance wants, make this more configurable later
            externalResolutionOptions = {
              low = {
                x = 3440;
                y = 1440;
                refresh = "84.964";
              };

              # Laggy on laptop external, look into more later but still usable for the glorious size...
              high = {
                x = 5120;
                y = 2160;
                refresh = "100.035";
              };
            };

            resolutions = {
              laptop = {
                x = 2560;
                y = 1440;
              };

              # Hardcoded so hard
              external = externalResolutionOptions.high;
            };

            positions = {
              laptop = {
                x = builtins.floor ((resolutions.external.x - resolutions.laptop.x) / (2 * cfg.scaleMain));
                y = builtins.floor (resolutions.external.y / cfg.scaleExternal);
              };
            };

            externalMode = with resolutions.external; "${toString x}x${toString y}@${refresh}";

            terminalCommand = if cfg.terminal == "kitty" then ''"kitty" "-1"'' else ''"${cfg.terminal}"'';

            # Slightly hacky but allow swapping between kb layouts
            # if we have JP as main, because I attach a US keyboard
            # via USB to these sometimes
            # https://man.archlinux.org/man/xkeyboard-config-2.7.en#LAYOUTS
            xkb =
              if cfgDesktop.kbLayout == "us" then
                ''
                  xkb {
                      layout "${cfgDesktop.kbLayout}"
                  }
                ''
              else
                ''
                  xkb {
                      layout "${cfgDesktop.kbLayout},us"
                      options "grp:shifts_toggle"
                  }
                '';
          in
          {
            text = ''
              // This config is in the KDL format: https://kdl.dev
              // "/-" comments out the following node.
              // Check the wiki for a full description of the configuration:
              // https://github.com/YaLTeR/niri/wiki/Configuration:-Introduction

              // Unhardcode outputs more later
              output "eDP-1" {
                scale ${toString cfg.scaleMain}

                position x=${toString positions.laptop.x} y=${toString positions.laptop.y}
              }
              output "LG Electronics LG ULTRAGEAR+ 508RMQK8A148" {
                scale ${toString cfg.scaleExternal}

                mode "${externalMode}"

                position x=0 y=0
              }

              input {
                  keyboard {
                      ${xkb}

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

                  empty-workspace-above-first

                  // When to center a column when changing focus, options are:
                  // - "never", default behavior, focusing an off-screen column will keep at the left
                  //   or right edge of the screen.
                  // - "always", the focused column will always be centered.
                  // - "on-overflow", focusing a column will center it if it doesn't fit
                  //   together with the previously focused column.
                  center-focused-column "never"

                  // Only floating windows use these now, via
                  // switch-preset-window-width - niri has no separate preset list
                  // for them.  Tiled columns go through niri-column-cycle on
                  // Mod+R, which derives its stops from the live column count
                  // instead of this fixed list.
                  preset-column-widths {
                      proportion 0.3333
                      proportion 0.5
                      proportion 0.6666
                  }

                  // You can also customize the heights that "switch-preset-window-height" (Mod+E) toggles between.
                  preset-window-heights {
                    proportion 0.3
                    proportion 0.5
                    proportion 0.7
                  }

                  // Only the starting value - the include below overrides this
                  // and is what niri-columns rewrites at runtime.
                  default-column-width { proportion ${toString (1.0 / cfg.defaultColumns)}; }

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
                    // Sides get more aggressive struts
                    left -${doubleBorderWidthPixels}
                    right -${doubleBorderWidthPixels}
                  }
              }

              spawn-at-startup "awww-daemon"

              environment {
              }

              cursor {
                xcursor-theme "${theme.cursorTheme.name}"
                xcursor-size ${toString cfg.cursorSize}
              }

              hotkey-overlay {
                  skip-at-startup
              }

              // Uncomment this line to ask the clients to omit their client-side decorations if possible.
              // If the client will specifically ask for CSD, the request will be honored.
              // Additionally, clients will be informed that they are tiled, removing some client-side rounded corners.
              // This option will also fix border/focus ring drawing behind some semitransparent windows.
              // After enabling or disabling this, you need to restart the apps for this to take effect.
              prefer-no-csd

              screenshot-path "~/.evertras/screenshots/%Y-%m-%d %H-%M-%S.png"

              // Apply to all windows
              window-rule {
                  // NOTE: This used to be true, but it's annoying on ultrawide... configurable in the future?
                  open-maximized false
              }

              // The live default column width, rewritten by the niri-columns func.
              // Relative includes resolve next to this config file, which is the
              // symlink in ~/.config/niri and not its store target, so this finds
              // the writable copy that home-manager seeds on activation.
              // NOTE: niri fails to load the whole config if this file is missing.
              include "${columnWidthFile}"

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

              // Terminals get partial screens
              window-rule {
                match app-id=r#"^${cfg.terminal}$"#

                open-maximized false
              }

              window-rule {
                  match app-id=r#"^discord$"#
                  match app-id=r#"^librewolf$"#

                  block-out-from "screencast"
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
                  Mod+Space hotkey-overlay-title="Open a Terminal: ${cfg.terminal}" { spawn ${terminalCommand}; }
                  Mod+P hotkey-overlay-title="Run an Application: launch-app" { spawn "launch-app"; }
                  // Super+Alt+L hotkey-overlay-title="Lock the Screen: swaylock" { spawn "swaylock"; }

                  XF86AudioRaiseVolume allow-when-locked=true { spawn "volume-up"; }
                  XF86AudioLowerVolume allow-when-locked=true { spawn "volume-down"; }
                  XF86AudioMute        allow-when-locked=true { spawn "volume-mute-toggle"; }

                  XF86MonBrightnessUp   { spawn "brightness-up"; }
                  XF86MonBrightnessDown { spawn "brightness-down"; }

                  // Open/close the Overview: a zoomed-out view of workspaces and windows.
                  // You can also move the mouse into the top-left hot corner,
                  // or do a four-finger swipe up on a touchpad.
                  Mod+O repeat=false { toggle-overview; }
                  Mod+MouseMiddle repeat=false { toggle-overview; }

                  Mod+Q { close-window; }

                  Mod+Left  { focus-column-left; }
                  Mod+Down  { focus-window-down; }
                  Mod+Up    { focus-window-up; }
                  Mod+Right { focus-column-right; }
                  Mod+H     { focus-column-left; }
                  Mod+J     { focus-window-down; }
                  Mod+K     { focus-window-up; }
                  Mod+L     { focus-column-right; }
                  Mod+MouseBack    { focus-column-left; }
                  Mod+MouseForward { focus-column-right; }

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

                  // Set how many columns fit on screen: resizes every open column
                  // and changes the default width for new windows.
                  Mod+Alt+2 hotkey-overlay-title="Fit 2 Columns On Screen" { spawn "niri-columns" "2"; }
                  Mod+Alt+3 hotkey-overlay-title="Fit 3 Columns On Screen" { spawn "niri-columns" "3"; }
                  Mod+Alt+4 hotkey-overlay-title="Fit 4 Columns On Screen" { spawn "niri-columns" "4"; }

                  // Cycles the focused column through the widths that fit the
                  // current column count, e.g. 1/4, 2/4, 3/4 with 4 columns.
                  // No repeat: each press spawns a process that reads the current
                  // width, so held-down repeats would race each other.
                  Mod+R repeat=false hotkey-overlay-title="Cycle Column Width" { spawn "niri-column-cycle"; }
                  Mod+E { switch-preset-window-height; }
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

                  Mod+Shift+N hotkey-overlay-title="Dismiss Slack Notifications" { spawn "notifications-dismiss-slack"; }

                  Mod+Shift+S { screenshot; }
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

      # Seed the included column width file if it isn't there yet.  It has to be a
      # real writable file rather than a home.file store symlink, since the whole
      # point is that niri-columns rewrites it at runtime.
      home.activation.niriColumnWidth = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -e "${columnWidthPath}" ]; then
          run mkdir -p "${columnWidthDir}"
          run install -m 644 "${initialColumnWidthFile}" "${columnWidthPath}"
        fi
      '';

      # An included file can carry its own layout node, so the preset list could
      # in principle be rewritten at runtime the way the default width is.  It
      # still wouldn't do what we want: niri cycles presets by index, so a
      # one-entry list re-applies that width instead of leaving a 2-column layout
      # alone, and an empty list parses but then has niri indexing a list with
      # nothing in it.  So do the cycling ourselves instead.
      evertras.home.shell.funcs.niri-column-cycle = {
        runtimeInputs = with pkgs; [
          gawk
          jq
          niri
        ];

        body = ''
          usage() {
            cat >&2 <<'USAGE'
          usage: niri-column-cycle

          Cycles the focused column through the widths that fit the number of
          columns currently set by niri-columns: 1/N through (N-1)/N.  Fewer
          than 3 columns leaves at most one such width, so nothing happens.
          USAGE
          }

          case "''${1-}" in
            "") ;;
            -h | --help)
              usage
              exit 0
              ;;
            *)
              usage
              exit 1
              ;;
          esac

          # Every query below tolerates its own failure rather than letting
          # errexit kill the script mid-way: niri spawns this with nowhere for
          # stderr to go, so a hard exit and a handled one look the same from
          # the keyboard, and the handled one at least leaves the width alone.
          window=$(niri msg -j focused-window) || window=""

          if [ -z "$window" ] || [ "$window" = "null" ]; then
            exit 0
          fi

          # Floating windows aren't in the scrolling layout at all, so leave them
          # to niri's own presets.
          if [ "$(jq -r '.is_floating' <<< "$window" || true)" = "true" ]; then
            niri msg action switch-preset-window-width
            exit 0
          fi

          # How many columns fit on screen is whatever proportion niri-columns
          # last wrote as the default width, so the count is 1/proportion.  The
          # file is only readable if it has been seeded, and awk exits non-zero
          # on a missing one, which under errexit would skip the fallback below.
          widthFile="${columnWidthPath}"
          columns=""

          # Regular file only: awk on a fifo or a character device would sit
          # there reading forever, and this runs off a keypress.
          if [ -f "$widthFile" ] && [ -r "$widthFile" ]; then
            columns=$(awk '
              /default-column-width/ && match($0, /proportion[[:space:]]+[0-9.]+/) {
                p = substr($0, RSTART, RLENGTH)
                sub(/proportion[[:space:]]+/, "", p)

                # Only a count that could have been written here in the first
                # place - 1000 is just past anything sane.  A tiny proportion
                # inverts to something huge, or to an infinity that %d prints as
                # text, either of which the stop search below would grind on.
                if (p + 0 > 0) {
                  n = int(1 / p + 0.5)

                  if (n >= 1 && n <= 1000) {
                    printf "%d", n
                    exit
                  }
                }
              }
            ' "$widthFile")
          fi

          case "$columns" in
            "" | *[!0-9]*) columns=${toString cfg.defaultColumns} ;;
          esac

          # Stops are k/columns for k in 1..columns-1, so under 3 columns there
          # is only the one width the column already opens at - nowhere to go.
          if [ "$columns" -lt 3 ]; then
            exit 0
          fi

          tileWidth=$(jq -r '.layout.tile_size[0] // empty' <<< "$window" || true)

          if [ -z "$tileWidth" ]; then
            echo "no tile size for the focused window" >&2
            exit 1
          fi

          # Whichever monitor holds the focused window is by definition the
          # focused one, so its width is what this column is measured against
          # and there is no need to walk workspaces looking for the output.
          outputWidth=$(niri msg -j focused-output | jq -r '.logical.width // empty' || true)

          if [ -z "$outputWidth" ]; then
            echo "no logical size for the focused output" >&2
            exit 1
          fi

          # Proportions are measured against the working area, which our negative
          # side struts make wider than the output itself.  Layer surfaces would
          # narrow it too, but waybar is a top bar and takes no width.
          percent=$(awk \
            -v tile="$tileWidth" \
            -v output="$outputWidth" \
            -v struts="${toString (sideStrutPixels * 2)}" \
            -v n="$columns" '
            BEGIN {
              current = tile / (output + struts)
              target = 1 / n

              # Slack to keep rounding, and any struts we guessed wrong about,
              # from making the stop we sit on look like the next one.  It has
              # to stay well under the 1/n gap between stops, and well over the
              # sub-pixel error, which a fixed value stops doing once n is large.
              slack = 0.25 / n

              if (slack > 0.01) {
                slack = 0.01
              }

              # Take the first stop wider than where we are now, wrapping back
              # around to the narrowest.
              for (k = 1; k < n; k++) {
                if (k / n > current + slack) {
                  target = k / n
                  break
                }
              }

              printf "%.4f", target * 100
            }
          ')

          niri msg action set-column-width "$percent%"
        '';
      };

      evertras.home.shell.funcs.niri-columns = {
        runtimeInputs = with pkgs; [
          gawk
          jq
          niri
        ];

        body = ''
          usage() {
            cat >&2 <<'USAGE'
          usage: niri-columns <count> [--all]

            count  how many columns should fit on screen, e.g. 2 or 3
            --all  also resize columns on workspaces that aren't currently visible

          Resizes the open columns and sets the width new windows open at.
          The count also decides which widths niri-column-cycle steps through.
          USAGE
          }

          columns=""
          all=false

          for arg in "$@"; do
            case "$arg" in
              --all) all=true ;;
              -h | --help)
                usage
                exit 0
                ;;
              *) columns="$arg" ;;
            esac
          done

          case "$columns" in
            "" | *[!0-9]*)
              usage
              exit 1
              ;;
          esac

          # Length first: a number too long to compare as an integer makes the
          # test itself fail, which reads the same as passing it.  The ceiling
          # also keeps the proportion meaningful once written out.
          if [ "''${#columns}" -gt 4 ] || [ "$columns" -lt 1 ] || [ "$columns" -gt 1000 ]; then
            usage
            exit 1
          fi

          # Niri parses a "%" width as a proportion of the working area, which is
          # the same thing preset-column-widths' "proportion" means, so the open
          # columns and the new default stay in sync.
          proportion=$(awk -v n="$columns" 'BEGIN { printf "%.6f", 1 / n }')
          percent=$(awk -v n="$columns" 'BEGIN { printf "%.4f", 100 / n }')

          # Write the default for new windows first.  Niri watches this file and
          # reloads on its own, and writing it atomically keeps niri from ever
          # reading a half-written config and rejecting it.
          widthFile="${columnWidthPath}"
          mkdir -p "${columnWidthDir}"
          tmpFile=$(mktemp "$widthFile.XXXXXX")
          trap 'rm -f "$tmpFile"' EXIT

          # niri-column-cycle reads the count back out of this with a regex over
          # a single line, so keep default-column-width and proportion together.
          cat > "$tmpFile" <<EOF
          // Generated - rewritten by the niri-columns func, do not edit by hand.
          window-rule {
              default-column-width { proportion $proportion; }
          }
          EOF

          chmod 644 "$tmpFile"
          mv "$tmpFile" "$widthFile"

          # Now the already-open columns.  set-column-width only ever applies to
          # the focused column, so walk them by focusing each in turn.
          windows=$(niri msg -j windows)
          workspaces=$(niri msg -j workspaces)

          focused=$(jq -r 'map(select(.is_focused)) | .[0].id // empty' <<< "$windows")

          if [ "$all" = true ]; then
            workspaceIds=$(jq -c 'map(.id)' <<< "$workspaces")
          else
            workspaceIds=$(jq -c '[.[] | select(.is_active) | .id]' <<< "$workspaces")
          fi

          # One window per column is enough, since the width is a column property.
          # Floating windows have no place in the scrolling layout, so skip them.
          columnWindowIds=$(jq -r --argjson wsIds "$workspaceIds" '
            [
              .[]
              | select(.is_floating | not)
              | select(.layout.pos_in_scrolling_layout != null)
              | select(.workspace_id as $id | $wsIds | index($id) != null)
            ]
            | group_by([.workspace_id, .layout.pos_in_scrolling_layout[0]])
            | map(.[0].id)
            | .[]
          ' <<< "$windows")

          while IFS= read -r id; do
            [ -n "$id" ] || continue

            # A window can close between the snapshot above and getting here.
            # Skip it rather than letting errexit strand focus mid-walk, which
            # would also skip putting it back at the end.
            if niri msg action focus-window --id "$id"; then
              niri msg action set-column-width "$percent%" || true
            fi
          done <<< "$columnWindowIds"

          # Focusing windows moved us around, so put every workspace back on the
          # window it was showing, and the originally focused window back last.
          if [ "$all" = true ]; then
            activeWindowIds=$(jq -r '.[] | select(.is_active) | .active_window_id // empty' <<< "$workspaces")

            while IFS= read -r id; do
              [ -n "$id" ] || continue

              niri msg action focus-window --id "$id" || true
            done <<< "$activeWindowIds"
          fi

          if [ -n "$focused" ]; then
            niri msg action focus-window --id "$focused" || true
          fi
        '';
      };
    }
  );
}
