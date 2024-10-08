{ lib, pkgs, ... }:

let
  themes = import ../../../shared/themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Green"; };
in {
  imports = [ ../../modules ../../../shared/themes/select.nix ];

  evertras.themes.selected = theme;

  evertras.home = {
    core.username = "evertras";

    desktop = {
      enable = true;
      kbLayout = "jp";

      windowmanager.i3 = {
        monitorNetworkInterface = "enp0s3";
        startupPostCommands = [ "xrandr --output Virtual1 --mode 2560x1440" ];
      };
    };
  };

  home = {
    # Other local things
    packages = [ ];

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
