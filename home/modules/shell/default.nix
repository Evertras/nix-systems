{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.shell;
  theme = config.evertras.themes.selected;
in {
  imports = [
    ./bash
    ./coding
    ./editorconfig
    ./fish
    ./funcs
    ./git
    ./neovim
    ./pass
    ./spotify
    ./starship
    ./tmux
  ];

  options.evertras.home.shell = {
    shell = mkOption {
      type = types.str;
      default = "bash";
    };

    prompt = mkOption {
      type = types.str;
      default = "starship";
    };

    # Note: need to bootstrap a GPG key before setting this,
    # maybe a better way in the future for fresh installs
    gpgKey = mkOption {
      type = with types; nullOr str;
      default = null;
    };
  };

  config = {
    home = {
      packages = with pkgs; [
        # General terminal tools
        asciigraph
        btop
        dig
        entr
        eza
        gcc
        git
        gnumake
        htop
        pinentry
        ripgrep
        silver-searcher
        sipcalc
        wget

        # Data processing
        fx
        fzf
        jq
        yq

        # Format nix things
        nixfmt

        # Funsies
        fastfetch
      ];

      sessionVariables = { EDITOR = "nvim"; };
    };

    programs = {
      direnv.enable = true;
      gpg = {
        enable = true;
        settings = {
          #pinentry-program = "${pkgs.pinentry}/bin/pinentry";
        };
      };
      tealdeer = {
        enable = true;

        settings = { updates.auto_update = true; };
      };
    };

    evertras.home.shell = {
      bash.enable = cfg.shell == "bash";
      editorconfig.enable = mkDefault true;
      starship.enable = cfg.prompt == "starship";
      tmux.enable = mkDefault true;

      funcs = {
        fonts.body =
          "fc-list : family | awk -F, '{print $1}' | grep Nerd | grep -E 'Mono$' | sort -u";
        show-color.body = ''
          perl -e 'foreach $a(@ARGV){print "\e[48:2::".join(":",unpack("C*",pack("H*",$a)))."m \e[49m "};print "\n"' "$@"
        '';

        cycle-wallpaper.body = "styli.sh -s '${theme.inspiration}'";

        git-merged.body = ''
          branch=$(git rev-parse --abbrev-ref HEAD)
          git checkout main
          git pull
          git branch -d "''${branch}"
        '';

        gadd.body = ''
          to_add=$(git status --porcelain | awk '/^ M/ || /^\?\?/ {print $2}' | fzf)
          if [ -n "$to_add" ]; then
            git add "$to_add"
            echo "Added $to_add"
          fi
        '';

        # Theme helpers for things we can't set directly
        theme-slack.body = let colors = theme.colors;
        in ''
          # Slack doesn't have any nice config, but we want to make it uniform with everything else...
          # we can import by copying this string
          #      background, selected, presence, notifications
          theme="${colors.background},${colors.primary},${colors.highlight},${colors.urgent}"
          echo "$theme" | xclip -selection clipboard
          echo "Theme copied to clipboard"
          echo "$theme"
        '';
        theme-firefox.body = "xdg-open https://github.com/catppuccin/firefox";
        theme-librewolf.body = "xdg-open https://github.com/catppuccin/firefox";

        # This is maddening to find otherwise... note this
        # also works for icons
        nix-find-cursor-names.body = ''
          if [ -z "$1" ]; then
            echo "Usage: nix-find-cursor-names <pkgname>"
            return
          fi
          package=$1
          storepath=$(nix eval -f '<nixpkgs>' --raw "''${package}")
          echo "Store path: ''${storepath}"
          ls "''${storepath}/share/icons"
        '';
        nix-find-theme-names.body = ''
            if [ -z "$1" ]; then
              echo "Usage: nix-find-theme-names <pkgname>"
              return
            fi
            package=$1
            storepath=$(nix eval -f '<nixpkgs>' --raw "''${package}")
            echo "Store path: ''${storepath}"
            ls "''${storepath}/share/themes"
          }
        '';
        nix-find-icon-names.body = ''
          storepath=${theme.iconTheme.package};
          themename=${theme.iconTheme.name};
          iconspath="''${storepath}/share/icons/''${themename}"
          echo "Store path: ''${storepath}"
          find "''${iconspath}" -name '*.svg' | awk -F/ '{print $NF}' | awk -F. '{print $1}' | sort -u | fzf
        '';
        nix-find-icon-names-in.body = ''
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
        '';

        # Some AWS helpers
        aws-connect.body = ''
          aws ssm start-session --target "''${1}"
        '';

        aws-ec2-list.body = ''
          aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" |
            jq -r '.Reservations | .[] | .Instances | .[] | { Id: .InstanceId, Name: (.Tags[] | select(.Key == "Name") | .Value) } | [.Name, .Id] | @tsv' |
            sort |
            column -t
        '';
      };

      git = {
        enable = mkDefault true;
        gpgKey = cfg.gpgKey;
      };

      pass = mkIf (cfg.gpgKey != null) {
        enable = true;
        gpgKey = cfg.gpgKey;
      };
    };
  };
}
