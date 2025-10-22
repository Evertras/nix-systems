{ config, everlib, lib, pkgs, ... }:

with lib;
let
  cfg = config.evertras.home.desktop;
  theme = config.evertras.themes.selected;
in {
  imports = everlib.allSubdirs ./.;

  options.evertras.home.desktop = {
    enable = mkEnableOption "desktop";

    terminal = mkOption {
      type = types.str;
      default = "kitty";
    };

    kbLayout = mkOption {
      type = types.str;
      default = "us";
    };

    resolution = mkOption {
      description = "Largest resolution of all monitors.";
      type = types.str;
      default = "2560x1440";
    };

    cursorSize = mkOption {
      description = "Cursor size";
      type = types.int;
      default = 32;
    };
  };

  config = mkIf cfg.enable (let
    usingWayland = cfg.windowmanager.hyprland.enable
      || cfg.windowmanager.niri.enable;
    usingXorg = cfg.windowmanager.i3.enable || cfg.windowmanager.dwm.enable;
  in {
    home.packages = with pkgs;
      let fontPackages = map (f: f.package) (attrsets.attrValues theme.fonts);
      in [
        # Clipboard
        xclip

        # xdg-open and friends
        # https://www.freedesktop.org/wiki/Software/xdg-utils/
        xdg-utils

        # Quick image manipulation with 'convert'
        imagemagick

        # Quick image viewing/editing
        feh
        gthumb

        # More extensive image editing
        gimp

        # Lots of video stuff, including capturing
        ffmpeg-full

        # Video players
        vlc
        mpv

        # Notes
        obsidian

        # Japanese fonts
        ipafont
        kochi-substitute

        # Use this to find xkb keys and inputs, etc.
        wev

        # Theme stuff
        theme.cursorTheme.package
        theme.gtkTheme.package
        theme.iconTheme.package
      ] ++ fontPackages;

    # Allows fontconfig to discover fonts installed by home-manager
    fonts.fontconfig.enable = true;

    xdg = {
      enable = true;
      mimeApps = {
        enable = true;
        defaultApplications = let
          defaultBrowser =
            "${config.evertras.home.desktop.browsers.default}.desktop";
        in {
          "text/html" = defaultBrowser;
          "x-scheme-handler/http" = defaultBrowser;
          "x-scheme-handler/https" = defaultBrowser;
          "x-scheme-handler/about" = defaultBrowser;
          "x-scheme-handler/unknown" = defaultBrowser;
        };
      };
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        cursor-theme = theme.cursorTheme.name;
        cursor-size = cfg.cursorSize;
      };
    };

    services = let
      # Savannah
      latitude = 32.0809;
      longitude = -81.0912;
    in {
      redshift = {
        enable = usingXorg;

        inherit latitude longitude;
      };

      wlsunset = {
        enable = usingWayland;

        temperature = {
          day = 7000;
          night = 3500;
        };

        latitude = toString latitude;
        longitude = toString longitude;
      };
    };

    evertras.home.desktop = {
      windowmanager = {
        dwm = {
          browser = mkDefault config.evertras.home.desktop.browsers.default;
        };

        i3 = { kbLayout = mkDefault cfg.kbLayout; };

        niri.cursorSize = mkDefault cfg.cursorSize;
      };

      bars.waybar.enable = mkDefault usingWayland;

      gtktheme.enable = mkDefault true;
      notifications = {
        enable = mkDefault true;
        wayland = mkDefault usingWayland;
      };

      dmenu.enable = mkDefault true;

      launchers.enable = mkDefault true;

      terminals = {
        alacritty.enable = mkDefault (cfg.terminal == "alacritty");
        kitty.enable = mkDefault (cfg.terminal == "kitty");
        st.enable = mkDefault (cfg.terminal == "st");
      };

      wallpaper.enable = true;

      vscode.enable = true;
    };

    evertras.home.shell.funcs = let
      screenshotsDir = "$HOME/.evertras/screenshots";
      screenshotsLog = "/tmp/screenshot-lastlog";
    in {
      screenshot-save = mkIf usingXorg {
        runtimeInputs = [ pkgs.maim ];
        body = ''
          mkdir -p "${screenshotsDir}"
          filename=${screenshotsDir}/$(date +%Y-%m-%d-%H-%M-%S | tr "[:upper:]" "[:lower:]").png

          if maim -us "$filename" | tee ${screenshotsLog}; then
            notify-send -i camera 'Screenshot' "$filename"
          else
            notify-send -i error -u critical "Screenshot error" "$(cat ${screenshotsLog})"
          fi
        '';
      };

      screenshot-copy = mkIf usingXorg {
        runtimeInputs = [ pkgs.maim pkgs.xclip ];
        body = ''
          if maim -us | tee ${screenshotsLog} | xclip -selection clipboard -t image/png; then
            notify-send -i camera 'Screen area copied'
          else
            notify-send -i error -u critical "Screenshot error" "$(cat ${screenshotsLog})"
          fi
        '';
      };
    };
  });
}
