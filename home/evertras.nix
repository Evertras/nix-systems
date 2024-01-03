{ config, pkgs, ... }:

{
  imports = [
    ./bash/bash.nix
    ./kitty/kitty.nix
  ];

  evertras.home = {
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

    # You can also manage environment variables but you will have to manually
    # source
    #
    #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    #
    # or
    #
    #  /etc/profiles/per-user/evertras/etc/profile.d/hm-session-vars.sh
    #
    # if you don't want to manage your shell through Home Manager.
    sessionVariables = {
      # EDITOR = "emacs";
    };

    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };

  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;

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
