{ lib, pkgs, ... }:

let
  themes = import ../../themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Green"; };
in {
  imports = [ ../modules ../../themes/select.nix ];

  evertras.themes.selected = theme;

  evertras.home = {
    core.username = "brandon-fulljames";

    desktop = {
      enable = true;

      # Already have firefox running/configured/bookmarked, maybe tweak later
      defaultBrowser = "firefox";
      kbLayout = "us";

      i3 = {
        monitorNetworkInterface = "eno1";

        keybindOverrides = { "Mod4+space" = "exec nixGL kitty"; };

        startupPreCommands = [
          "xrandr --output DP-2 --auto --output HDMI-0 --right-of DP-2 --auto --rotate left --output DP-1-3 --left-of DP-2 --auto"
        ];

        startupPostCommands = [
          # Prebuilt picom that works on this machine since it's not nixOS
          "/home/brandon-fulljames/bin/picom &"
        ];
      };
    };
  };

  # We have picom already installed and working via Ubuntu
  services.picom.enable = false;

  home = {
    # Other local things
    packages = with pkgs; [ awscli2 ];

    file = {
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
