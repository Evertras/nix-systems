{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.starship;
in {
  options.evertras.home.starship = { enable = mkEnableOption "starship"; };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;

      settings = {
        # TODO: only do this in WSL
        # This fixes a weird thing where it says "Systemd"
        # at the start of the prompt in WSL.
        # https://www.reddit.com/r/fishshell/comments/yhoi28/im_using_starship_prompt_in_wsl_and_it_keep/
        container.disabled = true;
      };
    };
  };
}
