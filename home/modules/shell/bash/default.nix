{ config, lib, ... }:
with lib;
let cfg = config.evertras.home.shell.bash;
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
          tree = "eza -T";
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

          # Include our funcs for easy access
          export PATH=~/.evertras/funcs:$PATH

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

          # Machine-specific bash stuff should go in this directory.
          # Mainly for any secret env vars or emergency modifications.
          if [ ! -d ~/.bashrc.d ]; then
            mkdir ~/.bashrc.d
          fi
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
