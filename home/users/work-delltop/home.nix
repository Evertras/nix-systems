{ lib, nerdfonts, pkgs, ... }:
let
  themes = import ../../../shared/themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Green"; };

  fontOverrides = {
    main = nerdfonts.make "CaskaydiaCove";
    terminal = nerdfonts.make "Hasklug";
  };

  gpgKey = "57F346A9FC11B688";
  wirelessInterface = "wlp0s20f3";
  externalOutput = "DP-2";
in {
  imports = [ ../../modules ../../../shared/themes/select.nix ];

  evertras.themes.selected =
    (theme // { fonts = (theme.fonts // fontOverrides); });

  evertras.home = {
    core.username = "evertras";

    tiledb.enable = true;

    audio = {
      enable = true;
      enableDesktop = true;
      headphonesMacAddress = "EC:66:D1:B8:95:88";
      volumeLimit = 60;
    };

    laptop = { enable = true; };

    shell = {
      core = { inherit gpgKey; };

      coding = {
        go.enable = true;
        nodejs.enable = true;
        rust.enable = true;
      };

      minikube.enable = true;

      funcs = {
        copy.body = ''
          wl-copy < "$1"
          echo -n "Char count: "
          wc --chars "$1" | awk '{print $1}'
          cat "$1"
        '';
      };
    };

    desktop = {
      enable = true;

      bars.waybar = {
        battery.name = "BAT0";
        monitorNetworkInterface = wirelessInterface;
      };

      browsers = {
        enableFirefox = true;
        default = "firefox";
      };

      display.sleep.enable = true;

      discord.enable = true;

      terminals.kitty = {
        fontName = fontOverrides.terminal.name;
        fontSize = 12;
        opacity = 0.8;
      };

      wallpaper = {
        randomWallpapersDir =
          "~/dev/github/evertras/wallpapers/external-rotation";

        outputs.external = externalOutput;
      };

      windowmanager = {
        niri = {
          enable = true;
          borderWidthPixels = 2;
          scaleMain = 1;
        };
      };
    };
  };

  home = {
    packages = with pkgs; [ packer slack ];

    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };
}
