{ lib, pkgs, ... }:

let
  themes = import ../../shared/themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Green"; };

  gpgKey = "9C6A5922D90A8465";

  displayLeft = "DP-1-3";
  displayCenter = "DP-2";
  displayRight = "HDMI-0";

  # Defined in funcs below
  terminal = "kitty-gl";
in {
  imports = [ ../modules ../../shared/themes/select.nix ];

  evertras.themes.selected = theme;

  evertras.home = let shellBin = "${pkgs.fish}/bin/fish";
  in {
    core.username = "brandon-fulljames";

    audio = {
      enable = true;
      enableDesktop = true;
      headphonesMacAddress = "EC:66:D1:B8:95:88";
    };

    shell = {
      inherit gpgKey;
      funcs = {
        aws-login.body = "aws sso login";
        kitty-gl.body = "nixGL kitty";
      };
      tmux.shell = shellBin;
    };

    desktop = let
    in {
      enable = true;

      browsers = {
        enableLibrewolf = false;
        enableChromium = true;

        # Already have firefox running/configured/bookmarked, maybe tweak later
        default = "firefox";
      };

      kbLayout = "us";

      display.sleep.enable = true;

      kitty.shell = shellBin;

      dwm = {
        enable = true;

        inherit terminal;
      };

      i3 = {
        monitorNetworkInterface = "eno1";

        # TODO: Fix 'Mod4'
        keybindOverrides = { "Mod4+space" = "exec ${terminal}"; };

        # Don't want status in right monitor since it's vertical
        bars = [
          {
            id = "main";
            outputs = [ displayLeft displayCenter ];
          }
          {
            id = "right";
            outputs = [ displayRight ];
            showStatus = false;
          }
        ];
      };
    };
  };

  # We have picom already installed and working via Ubuntu
  services.picom.enable = false;

  xsession.initExtra = ''
    # TODO: Could be fun making this a module?
    xrandr --output ${displayCenter} --auto --output ${displayRight} --right-of ${displayCenter} --auto --rotate left --output ${displayLeft} --left-of ${displayCenter} --auto
    # Prebuilt picom that works on this machine since it's not nixOS
    /home/brandon-fulljames/bin/picom &
  '';

  home = {
    # Other local things
    packages = with pkgs;
      [
        # Even without sound, allows remote control
        spotify-tui
      ];

    file = { ".asdfrc".text = "legacy_version_file = yes"; };

    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };
}
