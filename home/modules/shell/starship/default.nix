{ config, lib, ... }:
with lib;
let
  cfg = config.evertras.home.shell.starship;
  theme = config.evertras.themes.selected;
in {
  options.evertras.home.shell.starship = {
    enable = mkEnableOption "starship";
  };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;

      settings = {
        # Don't show info about being in a container.
        # This fixes a weird thing where it says "Systemd" at the start of the prompt in WSL.
        # https://www.reddit.com/r/fishshell/comments/yhoi28/im_using_starship_prompt_in_wsl_and_it_keep/
        # Additionally, I can't imagine a situation where I'm using starship in a container and being
        # unaware of it, so just disable it everywhere for simplicity.
        container.disabled = true;

        character = let
          # Funsies:
          # https://unicode-explorer.com/b/2980
          #char = "⟫";
          char = "❱❯";
        in {
          success_symbol = "[${char}](bold green)";
          error_symbol = "[${char}](bold red)";
        };

        directory = { style = "bold ${theme.colors.primary}"; };

        shell = {
          disabled = false;

          bash_indicator = "⍟";
          fish_indicator = "∫";
          style = "bold ${theme.colors.primary}";
        };
      };
    };
  };
}
