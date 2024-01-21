{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.evertras.home.desktop;
  theme = config.evertras.themes.selected;
in {
  imports = [
    ./browsers
    ./display
    ./dmenu
    ./dwm
    ./gtktheme
    ./i3
    ./kitty
    ./notifications
    ./st
  ];

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
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      let fontPackages = map (f: f.package) (attrsets.attrValues theme.fonts);
      in [
        # Clipboard
        xclip

        # Window management utilities
        # https://www.semicomplete.com/projects/xdotool/
        xdotool

        # Wallpaper changer
        stylish

        # Quick image manipulation with 'convert'
        imagemagick

        # Image viewing
        feh

        # Screenshot taker and more
        # https://github.com/naelstrof/maim#examples
        maim

        # Notes
        obsidian

        # Theme stuff
        theme.iconTheme.package
      ] ++ fontPackages;

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

    services = {
      redshift = {
        enable = true;

        # Tokyo generic
        latitude = 35.652832;
        longitude = 139.839478;
      };
    };

    evertras.home.desktop = {
      i3 = {
        enable = mkDefault true;
        kbLayout = mkDefault cfg.kbLayout;
      };

      dwm = {
        enable = mkDefault false;
        browser = mkDefault config.evertras.home.desktop.browsers.default;
      };

      gtktheme.enable = true;
      notifications.enable = mkDefault true;

      dmenu.enable = mkDefault true;

      # Terminals
      kitty.enable = mkDefault (cfg.terminal == "kitty");
      st.enable = mkDefault (cfg.terminal == "st");
    };

    evertras.home.shell.funcs = let
      screenshotsDir = "$HOME/.evertras/screenshots";
      screenshotsLog = "/tmp/screenshot-lastlog";
    in {
      screenshot-save.body = ''
        mkdir -p ${screenshotsDir}
        filename=${screenshotsDir}/$(date +%Y-%m-%d-%H-%M-%S | tr A-Z a-z).png
        maim -us "$filename" &> ${screenshotsLog}
        if [ $? == 0 ]; then
          notify-send -i camera 'Screenshot' "$filename"
        else
          notify-send -i error -u critical "Screenshot error" "$(cat ${screenshotsLog})"
        fi
      '';

      screenshot-copy.body = ''
        maim -us &> ${screenshotsLog} | xclip -selection clipboard -t image/png
        if [ $? == 0 ]; then
          notify-send -i camera 'Screen area copied'
        else
          notify-send -i error -u critical "Screenshot error" "$(cat ${screenshotsLog})"
        fi
      '';
    };
  };
}
