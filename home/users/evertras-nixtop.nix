{ lib, pkgs, ... }:
let
  themes = import ../../shared/themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Green"; };

  gpgKey = "ABFFF058F479311F";
in {
  imports = [ ../modules ../../shared/themes/select.nix ];

  evertras.themes.selected = theme;

  evertras.home = {
    core.username = "evertras";

    audio = {
      enable = true;
      enableDesktop = true;
      headphonesMacAddress = "EC:66:D1:B8:95:88";
    };

    laptop = {
      enable = true;
      brightnessIncrement = 10;
    };

    shell = {
      core = { inherit gpgKey; };

      spotify.enable = true;

      neovim.enableCopilot = true;

      coding.go.enable = true;
    };

    desktop = {
      enable = true;
      kbLayout = "jp";

      kitty.enable = true;
      st = {
        enable = true;

        bgImage = "/home/evertras/Pictures/wallpaper.ff";
        fontSize = 20;
      };

      display.sleep.enable = true;

      # Keeping for reference so I can switch back and forth
      i3 = {
        monitorNetworkInterface = "wlo1";
        monitorNetworkWireless = true;
        # Pipewire doesn't seem to want to start until
        # something kicks it, so kick it
        startupPostCommands = [ "systemctl restart --user pipewire" ];
        keybindOverrides = let brightnessIncrement = "10";
        in {
          XF86MonBrightnessUp =
            "exec ~/.evertras/funcs/brightness-change ${brightnessIncrement}%+";
          XF86MonBrightnessDown =
            "exec ~/.evertras/funcs/brightness-change ${brightnessIncrement}%-";
        };
      };
    };
  };

  home = let
  in {
    # Other local things
    packages = with pkgs;
      [
        # Laptop things
        brightnessctl
      ];

    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };
}
