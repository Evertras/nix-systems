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
        grep = "grep --color=auto";
        ls = "ls --color";
        mux = "tmuxinator";
        vi = "nvim";
        vim = "nvim";
      };

      shellInit = let
        rmp = strings.removePrefix "#";
        colorPrimary = rmp theme.colors.primary;
        colorText = rmp theme.colors.text;
        colorUrgent = rmp theme.colors.urgent;
      in ''
        set -g fish_greeting Everfish

        # Theme
        # TODO: Move this into theme file
        set -g fish_color_normal c6d0f5
        set -g fish_color_command 8caaee
        set -g fish_color_param eebebe
        set -g fish_color_keyword e78284
        set -g fish_color_quote a6d189
        set -g fish_color_redirection f4b8e4
        set -g fish_color_end ef9f76
        set -g fish_color_comment 838ba7
        set -g fish_color_error ${colorUrgent}
        set -g fish_color_gray 737994
        set -g fish_color_selection --background=414559
        set -g fish_color_search_match --background=414559
        set -g fish_color_option a6d189
        set -g fish_color_operator f4b8e4
        set -g fish_color_escape ea999c
        set -g fish_color_autosuggestion 737994
        set -g fish_color_cancel e78284
        set -g fish_color_cwd e5c890
        set -g fish_color_user 81c8be
        set -g fish_color_host 8caaee
        set -g fish_color_host_remote a6d189
        set -g fish_color_status e78284
        set -g fish_pager_color_progress 737994
        set -g fish_pager_color_prefix f4b8e4
        set -g fish_pager_color_completion c6d0f5
        set -g fish_pager_color_description 737994
      '';

      /* Scratchpad for future reference:
         fish --private
      */
    };
  };
}
