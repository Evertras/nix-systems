{ lib, pkgs, ... }:
let
  themes = import ../../shared/themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Green"; };

  gpgKey = "ABFFF058F479311F";
in {
  imports = [ ../modules ../../shared/themes/select.nix ];

  evertras.themes.selected = theme;

  evertras.home = let shellBin = "${pkgs.fish}/bin/fish";
  in {
    core.username = "evertras";

    audio = {
      enable = true;
      enableDesktop = true;
      headphonesMacAddress = "EC:66:D1:B8:95:88";
    };

    shell = {
      inherit gpgKey;

      spotify.enable = true;

      tmux.shell = shellBin;

      neovim.enableCopilot = true;

      funcs = {
        # TODO: move all this out into a configurable module
        brightness-change.body = ''
          level=$(brightnessctl -m set "$1" | awk -F, '{gsub(/%$/, "", $4); print $4}')
          notify-send "Brightness $level%" \
            -i brightnesssettings \
            -t 2000 \
            -h string:synchronous:screenbrightness \
            -h "int:value:$level"
        '';
      };
    };

    desktop = {
      enable = true;
      kbLayout = "jp";

      kitty.shell = shellBin;

      display.sleep.enable = true;

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
