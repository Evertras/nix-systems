{ config, pkgs, ... }:

{
  imports = [
    ../modules/all.nix
  ];

  evertras.home = {
    bash.enable = true;
    kitty.enable = true;
    starship.enable = true;
    tmux.enable = true;
  };

  home = {
    username = "evertras";
    homeDirectory = "/home/evertras";

    # Other local things
    packages = with pkgs; [
      librewolf
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
