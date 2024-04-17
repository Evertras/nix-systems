{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.shell.shells.fish;
  theme = config.evertras.themes.selected;
in {
  options.evertras.home.shell.shells.fish = {
    enable = mkEnableOption "Fish shell";
  };

  config = mkIf cfg.enable {
    home.file = {
      ".config/fish/completions/aws.fish" = {
        text = ''
          function __fish_complete_aws
            env COMP_LINE=(commandline -pc) aws_completer | tr -d ' '
          end

          complete -c aws -f -a "(__fish_complete_aws)"
        '';
      };
    };

    programs.fish = {
      enable = true;

      functions = {
        # Add !! and !$ to fish using the snippet below
        # https://github.com/fish-shell/fish-shell/wiki/Bash-Style-Command-Substitution-and-Chaining-(!!-!$)
        bind_bang = ''
          switch (commandline -t)
          case "!"
            commandline -t -- $history[1]
            commandline -f repaint
          case "*"
            commandline -i !
          end
        '';

        bind_dollar = ''
          switch (commandline -t)
          case "*!"
            commandline -f backward-delete-char history-token-search-backward
          case "*"
            commandline -i '$'
          end
        '';

        fish_user_key_bindings = ''
          bind ! bind_bang
          bind '$' bind_dollar
        '';

        coln = ''
          awk '{print $'$argv[1]'}'
        '';

        skip = ''
          tail -n +(math 1 + $argv[1])
        '';

        take = ''
          head -n $argv[1]
        '';
      };

      shellAbbrs = {
        aws-profile = ''
          export AWS_PROFILE=$(aws-profiles | fzf --height 20% || echo "none")'';
        cat = "bat -p";
        g = "git";
        gc = "git commit -m";
        gd = "git diff";
        gp = "git push";
        gs = "git status";
        jctluser = "journalctl --user";
        k = "kubectl";
        ndf = "nix develop --command fish";
        nr = "npm run";
        ls = "eza";
        private = "fish --private";
        sctluser = "systemctl --user";
        tree = "eza -T";
      };

      shellAliases = {
        grep = "grep --color=auto";
        mux = "tmuxinator";
        vi = "nvim";
        vim = "nvim";
        wget = "wget --hsts-file=$XDG_DATA_HOME/wget-hsts";
      };

      shellInit = let
        rmp = strings.removePrefix "#";
        colorPrimary = rmp theme.colors.primary;
        colorText = rmp theme.colors.text;
        colorUrgent = rmp theme.colors.urgent;

        mkEnvVar = name: value: "set ${name} ${value}";
        envVars =
          attrsets.mapAttrsToList mkEnvVar config.evertras.home.shell.env.vars;
      in ''
        set fish_greeting

        fish_add_path -g ~/.evertras/funcs
        fish_add_path -g ~/bin

        set GPG_TTY (tty)

        # Env vars from config.evertras.home.shell.env.vars
        ${concatStringsSep "\n" envVars}

        # Theme
        # TODO: Move this into theme file
        set fish_color_normal c6d0f5
        set fish_color_command 8caaee
        set fish_color_param eebebe
        set fish_color_keyword e78284
        set fish_color_quote a6d189
        set fish_color_redirection f4b8e4
        set fish_color_end ef9f76
        set fish_color_comment 838ba7
        set fish_color_error ${colorUrgent}
        set fish_color_gray 737994
        set fish_color_selection --background=414559
        set fish_color_search_match --background=414559
        set fish_color_option a6d189
        set fish_color_operator f4b8e4
        set fish_color_escape ea999c
        set fish_color_autosuggestion 737994
        set fish_color_cancel e78284
        set fish_color_cwd e5c890
        set fish_color_user 81c8be
        set fish_color_host 8caaee
        set fish_color_host_remote a6d189
        set fish_color_status e78284
        set fish_pager_color_progress 737994
        set fish_pager_color_prefix f4b8e4
        set fish_pager_color_completion c6d0f5
        set fish_pager_color_description 737994
      '';
    };
  };
}
