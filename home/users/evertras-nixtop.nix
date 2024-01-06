{ lib, pkgs, ... }:

let
  themes = import ../../themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Green"; };
in {
  imports = [ ../modules ../../themes/select.nix ];

  evertras.themes.selected = theme;

  evertras.home = {
    core.username = "evertras";

    shell = { git.gpgKey = "ABFFF058F479311F"; };

    desktop = {
      enable = true;
      kbLayout = "jp";

      i3 = {
        monitorNetworkInterface = "wlo1";
        monitorNetworkWireless = true;
        keybindOverrides = {
          XF86MonBrightnessUp = "exec brightnessctl set 10%+";
          XF86MonBrightnessDown = "exec brightnessctl set 10%-";
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
