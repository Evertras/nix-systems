{ pkgs, ... }:

{
  imports = [ ../modules ];

  evertras.home = {
    bash.enable = true;
    editorconfig.enable = true;
    git.enable = true;
    i3.enable = true;
    kitty.enable = true;
    starship.enable = true;
    tmux.enable = true;

    theming = {
      enable = true;

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

  home = {
    username = "evertras";
    homeDirectory = "/home/evertras";

    # Other local things
    packages = with pkgs; [
      # Desktop
      feh
      imagemagick
      librewolf

      # Coding
      cargo
      go
      nixfmt
      nodejs_21
      python3
      rustc
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
