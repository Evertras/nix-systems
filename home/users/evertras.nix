{ config, pkgs, ... }:

{
  imports = [
    ../modules/core/core.nix
    ../modules/bash/bash.nix
    ../modules/kitty/kitty.nix
  ];

  evertras.home = {
    bash.enable = true;
    kitty.enable = true;
  };

  home = {
    username = "evertras";
    homeDirectory = "/home/evertras";

    # Local things
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

  programs = {
    starship = {
      enable = true;

      settings = {
        # TODO: only do this in WSL
        # This fixes a weird thing where it says "Systemd"
        # at the start of the prompt in WSL.
        # https://www.reddit.com/r/fishshell/comments/yhoi28/im_using_starship_prompt_in_wsl_and_it_keep/
        #container.disabled = true;
      };
    };
  };
}
