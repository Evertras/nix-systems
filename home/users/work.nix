{ lib, pkgs, ... }:

let
  themes = import ../../themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Green"; };

  gpgKey = "9C6A5922D90A8465";

  displayLeft = "DP-1-3";
  displayCenter = "DP-2";
  displayRight = "HDMI-0";
in {
  imports = [ ../modules ../../themes/select.nix ];

  evertras.themes.selected = theme;

  evertras.home = {
    core.username = "brandon-fulljames";

    shell = { inherit gpgKey; };

    desktop = {
      enable = true;

      browsers = {
        enableLibrewolf = false;
        enableChromium = true;

        # Already have firefox running/configured/bookmarked, maybe tweak later
        default = "firefox";
      };

      kbLayout = "us";

      i3 = {
        monitorNetworkInterface = "eno1";

        # TODO: Fix 'Mod4'
        keybindOverrides = { "Mod4+space" = "exec nixGL kitty"; };

        startupPreCommands = [
          # TODO: Could be fun making this a module?
          "xrandr --output ${displayCenter} --auto --output ${displayRight} --right-of ${displayCenter} --auto --rotate left --output ${displayLeft} --left-of ${displayCenter} --auto"
        ];

        startupPostCommands = [
          # Prebuilt picom that works on this machine since it's not nixOS
          "/home/brandon-fulljames/bin/picom &"

          # Screensaver, eventually... maybe?  Keeping for now for quick reference/inspiration
          #"xset s 3600"

          # Monitor sleep settings (TODO: pull this into desktop config)
          # Units in seconds
          # man xset -> "The first value given is for the ‘standby' mode, the second is for the ‘suspend' mode, and the third is for the ‘off' mode."
          # So basically, standby after 10 minutes, then suspend after an hour, then turn off after 3 hours
          "xset dpms 600 3600 10800"
        ];

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

  home = {
    # Other local things
    packages = with pkgs;
      [
        # Even without sound, allows remote control
        spotify-tui
      ];

    file = {
      ".asdfrc".text = "legacy_version_file = yes";

      # # Building this configuration will create a copy of 'dotfiles/screenrc' in
      # # the Nix store. Activating the configuration will then make '~/.screenrc' a
      # # symlink to the Nix store copy.
      # ".screenrc".source = dotfiles/screenrc;

      # # You can also set the file content immediately.
      # ".gradle/gradle.properties".text = ''
      #   org.gradle.console=verbose
      #   org.gradle.daemon.idletimeout=3600000
      # '';
    };

    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };
}
