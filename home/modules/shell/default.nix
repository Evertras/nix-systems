{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.shell;
in {
  imports = [ ./bash ./editorconfig ./git ./neovim ./starship ./tmux ];

  options.evertras.home.shell = {
    shell = mkOption {
      type = types.str;
      default = "bash";
    };

    prompt = mkOption {
      type = types.str;
      default = "starship";
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
        tldr
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
      gpg.enable = true;
    };

    evertras.home.shell = {
      bash.enable = cfg.shell == "bash";
      editorconfig.enable = mkDefault true;
      git.enable = mkDefault true;
      starship.enable = cfg.prompt == "starship";
      tmux.enable = mkDefault true;
    };
  };
}
