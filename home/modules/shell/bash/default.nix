{ config, lib, ... }:
with lib;
let
  cfg = config.evertras.home.shell.bash;
  theme = config.evertras.themes.selected;
in {
  options.evertras.home.shell.bash = { enable = mkEnableOption "bash"; };

  config = mkIf cfg.enable {
    programs = {
      bash = {
        enable = true;

        shellAliases = {
          f = "fish";
          grep = "grep --color=auto";
          jctluser = "journalctl --user";
          k = "kubectl";
          ls = "ls --color";
          mux = "tmuxinator";
          nr = "npm run";
          reloadbash = "source ~/.bashrc";
          sctluser = "systemctl --user";
          vi = "nvim";
          vim = "nvim";
        };

        # bashrcExtra for all shells, initExtra for interactive only
        # TODO: move functions into own package along with other
        # random funcs scattered around other files
        initExtra = ''
          # Don't show control characters
          stty -echoctl

          # Make GPG signing happen in the correct terminal
          export GPG_TTY="$(tty)"

          # Simple Makefile completion
          complete -W "\`grep -oE '^[a-zA-Z0-9_-]+:([^=]|$)' Makefile | sed 's/[^a-zA-Z0-9_-]*$//'\`" make

          # For any secret env vars or emergency modifications
          if [ ! -d ~/.bashrc.d ]; then
            mkdir ~/.bashrc.d
          fi
          for src in ~/.bashrc.d/*; do
            if [[ -f "''${src}" ]]; then
              source "''${src}"
            fi
          done

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

          function kitty-reload() {
            kill -SIGUSR1 $(pgrep kitty)
          }

          function kitty-theme() {
            kitten theme --reload-in=all --config-file-name theme.conf
            sleep 1 && kitty-reload
          }

          function fonts() {
            fc-list : family | awk -F, '{print $1}' | grep Nerd | grep -E 'Mono$' | sort -u
          }

          function show-color() {
            perl -e 'foreach $a(@ARGV){print "\e[48:2::".join(":",unpack("C*",pack("H*",$a)))."m \e[49m "};print "\n"' "$@"
          }

          function cycle-wallpaper() {
            styli.sh -s '${theme.inspiration}'
          }

          # Keeping for reference but not actually using it...
          function deprecated-retheme() {
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

          # This is maddening to find otherwise... note this
          # also works for icons
          function nix-find-cursor-names() {
            if [ -z "$1" ]; then
              echo "Usage: nix-find-cursor-names <pkgname>"
              return
            fi
            package=$1
            storepath=$(nix eval -f '<nixpkgs>' --raw "''${package}")
            echo "Store path: ''${storepath}"
            ls "''${storepath}/share/icons"
          }
          function nix-find-theme-names() {
            if [ -z "$1" ]; then
              echo "Usage: nix-find-theme-names <pkgname>"
              return
            fi
            package=$1
            storepath=$(nix eval -f '<nixpkgs>' --raw "''${package}")
            echo "Store path: ''${storepath}"
            ls "''${storepath}/share/themes"
          }
          function nix-find-icon-name-in() {
            if [ -z "$2" ]; then
              echo "Usage: nix-find-icon-name-in <pkgname> <theme-name>"
              return
            fi
            package=$1
            themename=$2
            storepath=$(nix eval -f '<nixpkgs>' --raw "''${package}")
            iconspath="''${storepath}/share/icons/''${themename}"
            echo "Store path: ''${storepath}"
            find "''${iconspath}" -name '*.svg' | awk -F/ '{print $NF}' | awk -F. '{print $1}' | sort -u | fzf
          }

          function gen-theme-slack() {
            # Slack doesn't have any nice config, but we want to make it uniform with everything else...
            # we can import a slack theme as described below.
            # https://github.com/catppuccin/slack
            # Original string #303446,#F8F8FA,#CA9EE6,#303446,#232634,#C6D0F5,#CA9EE6,#EA999C,#303446,#C6D0F5
            echo "${theme.colors.background},${theme.colors.text},${theme.colors.primary},${theme.colors.background},${theme.colors.background},#C6D0F5,${theme.colors.primary},${theme.colors.urgent},${theme.colors.background},#C6D0F5"
          }
        '';
      };
    };
  };
}
