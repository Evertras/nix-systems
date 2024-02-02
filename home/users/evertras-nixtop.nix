{ lib, nerdfonts, pkgs, ... }:
let
  themes = import ../../shared/themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Green"; };

  gpgKey = "ABFFF058F479311F";
in {
  imports = [ ../modules ../../shared/themes/select.nix ];

  evertras.themes.selected = (theme // {
    fonts = (theme.fonts // { terminal = nerdfonts.makeMono "Hasklug"; });
  });

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

      neovim.enableCopilot = true;

      coding.go.enable = true;
    };

    desktop = {
      enable = true;
      kbLayout = "jp";

      browsers.surf.enable = true;

      kitty.enable = true;
      st = {
        enable = true;
        fontSize = 20;
        bgBlurPixels = 0;
        bgOpacityPercent100 = 90;
      };

      display.sleep.enable = true;
      windowmanager = {
        dwm = {
          enable = true;
          autostartCmds = [
            "feh --bg-fill /home/evertras/Pictures/desktops/waterfall-1.jpg"

            # For some reason this needs a kick
            "systemctl restart --user pipewire"
          ];
          borderpx = 2;
          terminal = "kitty";
        };

        # Keeping for reference so I can switch back and forth
        i3 = {
          enable = false;
          monitorNetworkInterface = "wlo1";
          monitorNetworkWireless = true;
          # Pipewire doesn't seem to want to start until
          # something kicks it, so kick it
          startupPostCommands = [ "systemctl restart --user pipewire" ];
          keybindOverrides = {
            XF86MonBrightnessUp = "exec ~/.evertras/funcs/brightness-up";
            XF86MonBrightnessDown = "exec ~/.evertras/funcs/brightness-down";
          };
        };
      };
    };
  };

  services.picom = {
    enable = true;
    vSync = true;
  };

  home = {
    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };
}
