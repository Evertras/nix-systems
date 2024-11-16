{ config, lib, ... }:
with lib;
let
  cfg = config.evertras.home.shell.starship;
  theme = config.evertras.themes.selected;
in {
  options.evertras.home.shell.starship = {
    enable = mkEnableOption "starship";

    indicatorBash = mkOption {
      type = types.str;
      default = "β";
    };

    indicatorFish = mkOption {
      type = types.str;
      default = "∫";
    };
  };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;

      settings = {
        aws.format = "[$symbol($profile )(\\[$duration\\] )]($style)";

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
          success_symbol = "[${char}](bold ${theme.colors.primary})";
          error_symbol = "[${char}](bold ${theme.colors.urgent})";
        };

        directory.style = "bold ${theme.colors.primary}";

        gcloud.disabled = true;

        golang.format = "[$symbol($version )]($style)";

        nix_shell.format = "[❄️ ]($style)";

        shell = {
          disabled = false;

          bash_indicator = cfg.indicatorBash;
          fish_indicator = cfg.indicatorFish;

          style = "bold ${theme.colors.primary}";
        };

        shlvl = {
          disabled = false;

          format = "[$symbol ]($style)";
          symbol = "❯";
          repeat = true;
          repeat_offset = 2;

          style = "bold cyan";
        };

        vagrant.disabled = true;
      };
    };
  };
}
