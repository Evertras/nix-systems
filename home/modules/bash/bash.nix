{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.bash;
in {
  options.evertras.home.bash = { enable = mkEnableOption "bash"; };

  config = mkIf cfg.enable {
    programs = {
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

          # For funsies, only adjusts kitty theme for now
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
    };
  };
}
