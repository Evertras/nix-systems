{ pkgs, ... }:

let themes = import ../../themes/themes.nix { inherit pkgs; };
in {
  imports = [ ../modules ../../themes/select.nix ];

  evertras.themes.selected = themes.mint;

  evertras.home = {
    core.username = "evertras";

    desktop = {
      enable = true;
      kbLayout = "jp";

      i3 = {
        monitorNetworkInterface = "enp0s3";
        xrandrExec = "xrandr --output Virtual1 --mode 2560x1440";
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
