{ config, pkgs, ... }:

{
  home = {
    username = "evertras";
    homeDirectory = "/home/evertras";

    # Local things
    packages = [
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

    bash = {
      enable = true;
      shellAliases = {
        grep = "grep --color=auto";
        k = "kubectl";
        ls = "ls --color";
        mux = "tmuxinator";
        nr = "npm run";
        reloadbash = "source ~/.bashrc";
        vim = "nvim";
      };

      # bashrcExtra for all shells, initExtra for interactive only
      initExtra = ''
        # Don't show control characters
        stty -echoctl

        # Make GPG signing happen in the correct terminal
        export GPG_TTY="$(tty)"

        # Simple Makefile completion
        complete -W "\`grep -oE '^[a-zA-Z0-9_-]+:([^=]|$)' Makefile | sed 's/[^a-zA-Z0-9_-]*$//'\`" make

        # Usage: up [n]
        #
        # Example: 'up 3' goes up 3 directories
        up() {
          local d=""
          limit=$1
          for((i=1 ; i <= limit ; i++))
            do
              d=$d/..
            done

          d=$(echo $d | sed 's/^\///')
          if [ -z "$d" ]; then
            d=..
          fi

          cd $d
        }

        function git-merged() {
          branch=$(git rev-parse --abbrev-ref HEAD)
          git checkout main
          git pull
          git branch -d "''${branch}"
        }

        function aws-connect() {
          aws ssm start-session --target "''${1}"
        }

        function aws-ec2-list() {
          aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" |
            jq -r '.Reservations | .[] | .Instances | .[] | { Id: .InstanceId, Name: (.Tags[] | select(.Key == "Name") | .Value) } | [.Name, .Id] | @tsv' |
            sort |
            column -t
        }

        function kitty-theme() {
          kitten theme --reload-in=all --config-file-name theme.conf
          kill -SIGUSR1 $(pgrep kitty)
        }

        function kitty-reload() {
          kill -SIGUSR1 $(pgrep kitty)
        }

        function fonts() {
          fc-list : family | awk -F, '{print $1}' | grep Nerd | grep -E 'Mono$' | sort -u
        }

        function show-color() {
            perl -e 'foreach $a(@ARGV){print "\e[48:2::".join(":",unpack("C*",pack("H*",$a)))."m \e[49m "};print "\n"' "$@"
        }

        function retheme() {
          searchterm="$@"
          if [ -z "''${searchterm}" ]; then
            searchterm=mountain
          fi

          if ! type schemer2 &> /dev/null; then
            mkdir -p ~/bin
            GOBIN=~/bin/schemer2 go install github.com/thefryscorer/schemer2@latest
          fi

          echo "Retheming to ''${searchterm}"
          styli.sh -s "''${searchterm}"
          colors=$(schemer2 -format img::colors -in ~/.cache/styli.sh/wallpaper.jpg)
          IFS=$'\n'
          for color in ''${colors}; do
            # Hijacked from show-color above
            perl -e 'foreach $a(@ARGV){print "\e[48:2::".join(":",unpack("C*",pack("H*",$a)))."m \e[49m"};' "''${color:1}"
          done
          schemer2 -format img::kitty -in ~/.cache/styli.sh/wallpaper.jpg > ~/.config/kitty/theme.conf
          kill -SIGUSR1 $(pgrep kitty)
        }

        # Machine-specific bash stuff should go in this directory
        if [[ -d ~/.bashrc.d ]]; then
          for src in ~/.bashrc.d/*; do
            if [[ -f ''${src} ]]; then
              source ''${src}
            fi
          done
        fi
      '';
    };

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
