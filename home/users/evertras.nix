{ pkgs, ... }:

let themes = import ../../themes/themes.nix;
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
        startupWallpaperTerm = "forest";
        xrandrExec = "xrandr --output Virtual1 --mode 2560x1440";

        font = {
          name = "Terminess Nerd Font";
          size = 16.0;
        };
      };

      theming = {
        font.name = "ComicShannsMono Nerd Font";

        # Fun ones to go back to:
        # nordzy-cursor-theme / Nordzy-cursors-white
        cursor = {
          name = "Bibata-Modern-Ice";
          package = pkgs.bibata-cursors;
          size = 30;
        };

        # Fun ones to go back to:
        # orchis-theme / Orchis-Purple-Dark-Compact
        overall = {
          name = "Layan-Dark";
          package = pkgs.layan-gtk-theme;
        };
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
