{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.shell;
in {
  imports = [
    ./bash
    ./editorconfig
    ./fish
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
      tealdeer.enable = true;
    };

    evertras.home.shell = {
      bash.enable = cfg.shell == "bash";
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
