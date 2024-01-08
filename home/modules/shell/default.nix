{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.shell;
  theme = config.evertras.themes.selected;
in {
  imports = [
    ./bash
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
        dig
        eza
        git
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

        # Coding
        cargo
        gcc
        go
        gnumake
        nixfmt
        nodejs_21
        python3
        rustc

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

        # Theme helpers for things we can't set directly
        theme-slack.body = ''
          # Slack doesn't have any nice config, but we want to make it uniform with everything else...
          # we can import a slack theme as described below.
          # https://github.com/catppuccin/slack
          # Original string #303446,#F8F8FA,#CA9EE6,#303446,#232634,#C6D0F5,#CA9EE6,#EA999C,#303446,#C6D0F5
          echo "${theme.colors.background},${theme.colors.text},${theme.colors.primary},${theme.colors.background},${theme.colors.background},#C6D0F5,${theme.colors.primary},${theme.colors.urgent},${theme.colors.background},#C6D0F5"
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
        nix-find-icon-name-in.body = ''
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
