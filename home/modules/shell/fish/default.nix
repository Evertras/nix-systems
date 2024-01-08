{ config, lib, pkgs, ... }:
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

      # TODO: Figure out how to get this working, it installs but isn't found on theme change
      /* plugins = [
           {
             name = "z";
             src = pkgs.fetchFromGitHub {
               owner = "catppuccin";
               repo = "fish";
               rev = "0ce27b518e8ead555dec34dd8be3df5bd75cff8e";
               sha256 = "sha256-Dc/zdxfzAUM5NX8PxzfljRbYvO9f9syuLO8yBr+R3qg=";
             };
           }
         ];
      */

      /* Scratchpad for future reference:
         fish --private (basically fish incognito, no history save, useful for dealing with credentials)
      */
    };
  };
}
