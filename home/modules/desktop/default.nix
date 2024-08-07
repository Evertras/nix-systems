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
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      let fontPackages = map (f: f.package) (attrsets.attrValues theme.fonts);
      in [
        # Clipboard
        xclip

        # xdg-open and friends
        # https://www.freedesktop.org/wiki/Software/xdg-utils/
        xdg-utils

        # Window management utilities
        # https://www.semicomplete.com/projects/xdotool/
        xdotool

        # Wallpaper changer
        stylish

        # Quick image manipulation with 'convert'
        imagemagick

        # Quick image viewing/editing
        feh
        gthumb

        # Lots of video stuff, including capturing
        ffmpeg-full

        # Screenshot taker and more
        # https://github.com/naelstrof/maim#examples
        maim

        # Notes
        obsidian

        # Japanese fonts
        ipafont
        kochi-substitute

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

    services = let
      usingWayland = cfg.windowmanager.hyprland.enable;
      usingXorg = cfg.windowmanager.i3.enable || cfg.windowmanager.dwm.enable;

      # Tokyo generic
      latitude = 35.652832;
      longitude = 139.839478;
    in {
      redshift = {
        enable = usingXorg;

        inherit latitude longitude;
      };

      wlsunset = {
        enable = usingWayland;

        temperature = {
          day = 6500;
          night = 4000;
        };

        latitude = toString latitude;
        longitude = toString longitude;
      };
    };

    evertras.home.desktop = {
      windowmanager = {
        dwm = {
          enable = mkDefault false;
          browser = mkDefault config.evertras.home.desktop.browsers.default;
        };

        i3 = {
          enable = mkDefault true;
          kbLayout = mkDefault cfg.kbLayout;
        };
      };

      gtktheme.enable = mkDefault true;
      notifications.enable = mkDefault true;

      dmenu.enable = mkDefault true;

      terminals = {
        alacritty.enable = mkDefault (cfg.terminal == "alacritty");
        kitty.enable = mkDefault (cfg.terminal == "kitty");
        st.enable = mkDefault (cfg.terminal == "st");
      };
    };

    evertras.home.shell.funcs = let
      screenshotsDir = "$HOME/.evertras/screenshots";
      screenshotsLog = "/tmp/screenshot-lastlog";
    in {

      cycle-wallpaper = {
        runtimeInputs = [ pkgs.stylish ];
        body = let
          split = splitString "x" cfg.resolution;
          width = elemAt split 0;
          height = elemAt split 1;
        in "styli.sh -s '${theme.inspiration}' -b bg-fill -h ${height} -w ${width}";
      };

      screenshot-save = {
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

      screenshot-copy = {
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
  };
}
