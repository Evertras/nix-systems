{ lib, nerdfonts, pkgs, ... }:
let
  themes = import ../../../shared/themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Green"; };

  berkeleyFont = {
    name = "Berkeley Mono";
    package = pkgs.everfont-berkeley;
  };

  fontOverrides = {
    main = nerdfonts.make "CaskaydiaCove";
    terminal = nerdfonts.make "Hasklug";
    #terminal = berkeleyFont;
  };

  gpgKey = "ABFFF058F479311F";
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

    #games = { lutris.enable = true; };

    laptop = { enable = true; };

    shell = {
      core = { inherit gpgKey; };

      # Using vscode when I want copilot for now,
      # but keeping as reference.
      #neovim = { enableCopilot = true; };

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

        ff-tiledb.body = ''
          firefox -P TileDB
        '';

        ff-me.body = ''
          firefox -P default
        '';
      };
    };

    desktop = {
      enable = true;
      kbLayout = "jp";

      browsers = {
        enableFirefox = true;
        default = "firefox";
      };

      display.sleep.enable = true;

      discord.enable = true;

      terminals.kitty = {
        fontName = fontOverrides.terminal.name;
        opacity = 0.8;
        backgroundOverride = "#000000";
      };

      windowmanager.niri = {
        enable = true;
        borderWidthPixels = 2;
      };
    };
  };

  home = {
    # Other fun things
    packages = with pkgs; [ cockatrice slack ];

    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };
}
