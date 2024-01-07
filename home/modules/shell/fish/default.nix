{ config, lib, ... }:
with lib;
let theme = config.evertras.themes.selected;
in {
  config = {
    programs.fish = {
      enable = true;

      shellAbbrs = {
        jctluser = "journalctl --user";
        k = "kubectl";
        nr = "npm run";
        sctluser = "systemctl --user";
      };

      shellAliases = {
        cycle-wallpaper = "styli.sh -s ${theme.inspiration}";
        grep = "grep --color=auto";
        ls = "ls --color";
        mux = "tmuxinator";
        vi = "nvim";
        vim = "nvim";
      };

      shellInit = let
        colorPrimary = string.removePrefix "#" theme.colors.primary;
        colorText = string.removePrefix "#" theme.colors.text;
      in ''
        set -U fish_greeting Everfish
      '';

      /* Scratchpad for future reference:
         fish --private (basically fish incognito, no history save, useful for dealing with credentials)
      */
    };
  };
}
