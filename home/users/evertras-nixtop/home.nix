{ lib, nerdfonts, pkgs, ... }:
let
  themes = import ../../../shared/themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Sky"; };

  fontOverrides = {
    terminal = nerdfonts.makeMono "Mononoki";
    main = nerdfonts.makeMono "AurulentSansM";
  };

  gpgKey = "ABFFF058F479311F";

  displayMain = {
    name = "eDP-1";
    resolution = "2560x1440";
    refreshRate = 240;
  };
in {
  imports = [ ../../modules ../../../shared/themes/select.nix ];

  evertras.themes.selected =
    (theme // { fonts = (theme.fonts // fontOverrides); });

  evertras.home = {
    core.username = "evertras";

    audio = {
      enable = true;
      enableDesktop = true;
      headphonesMacAddress = "EC:66:D1:B8:95:88";
    };

    laptop = { enable = true; };

    shell = {
      core = { inherit gpgKey; };

      spotify.enable = true;

      neovim = { enableCopilot = true; };

      coding.rust.enable = true;
    };

    desktop = {
      enable = true;
      kbLayout = "jp";

      display.sleep.enable = true;

      ime.enable = true;

      windowmanager = {
        hyprland = {
          enable = true;
          kbLayout = "jp";

          displays = [ (displayMain // { scale = 1.2; }) ];
        };

        # Keeping as reference for now
        dwm = {
          enable = false;
          autostartCmds = [
            "feh --bg-fill /home/evertras/Pictures/desktops/waterfall-1.jpg --no-fehbg"

            # For some reason this needs a kick
            "systemctl restart --user pipewire"
          ];
          borderpx = 2;
        };
      };
    };
  };

  home = {
    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };
}
