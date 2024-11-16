{ config, everlib, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.shell.core;
  theme = config.evertras.themes.selected;
in {
  imports = everlib.allSubdirs ./.;

  options.evertras.home.shell.core = {
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

    shellBin = mkOption {
      type = types.str;
      default = "${pkgs.fish}/bin/fish";
    };
  };

  config = {
    home = {
      packages = with pkgs; [
        # General terminal tools
        dig # DNS lookup
        entr # run commands on file changes
        gcc # for compiling things
        git # for git
        gnumake # for everything
        gum # for terminal scripts https://github.com/charmbracelet/gum
        ncdu # disk space usage
        nethogs # network usage monitoring
        pinentry # for gpg
        ranger # file explorer
        scc # code stats
        sipcalc # for IP calculations
        unzip # for unzipping things
        wget # for downloading things quickly
        whois # DNS info

        # Base tool upgrades
        bat # cat with syntax highlighting / paging
        btop # fancy top
        eza # nicer ls
        ripgrep # for nvim plugin searching in particular
        silver-searcher # for searching, does some things that rg doesn't (like -F for fixed strings)
        xh # Friendlier curl

        # Extras
        ssm-session-manager-plugin
        google-cloud-sdk

        # Data processing
        asciigraph
        fx
        jq
        pandoc
        yq

        # Format nix things
        nixfmt-classic

        # Funsies
        cynomys
        fastfetch
        presenterm
        quickview
        toipe
      ];

      sessionVariables = {
        EDITOR = "nvim";
        SHELL = cfg.shellBin;
      };
    };

    programs = {
      awscli = { enable = true; };

      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      fzf = {
        enable = true;

        # https://minsw.github.io/fzf-color-picker/
        colors = {
          # Where typing
          prompt = theme.colors.primary;

          # What the selection is pointing at right now
          # Sits behind "fg+", so make it blend in with text
          pointer = theme.colors.background;

          "bg+" = theme.colors.highlight;
          "fg+" = theme.colors.background;
          "hl" = theme.colors.primary;
          "hl+" = theme.colors.background;
        };
      };

      gpg = {
        enable = true;
        settings = {
          #pinentry-program = "${pkgs.pinentry}/bin/pinentry";
        };
      };

      # mise is like asdf but faster
      mise.enable = true;

      tealdeer = {
        enable = true;

        settings = { updates.auto_update = true; };
      };

      # Nicer cd
      # https://github.com/ajeetdsouza/zoxide
      zoxide.enable = true;
    };

    evertras.home.shell = {
      shells = {
        bash.enable = mkDefault true;
        fish.enable = mkDefault true;
      };

      editorconfig.enable = mkDefault true;
      starship.enable = cfg.prompt == "starship";
      tmux.enable = mkDefault true;

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
