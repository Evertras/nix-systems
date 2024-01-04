{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.shell;
in {
  imports = [ ./bash ./editorconfig ./git ./starship ./tmux ];

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
    home.packages = with pkgs; [
      # General terminal tools
      dig
      fzf
      gcc
      git
      htop
      jq
      neovim
      pinentry
      ripgrep
      silver-searcher
      tldr
      yq

      # Coding
      cargo
      go
      gnumake
      nixfmt
      nodejs_21
      python3
      rustc
    ];

    programs.direnv.enable = true;

    evertras.home.shell = {
      bash.enable = cfg.shell == "bash";
      editorconfig.enable = mkDefault true;
      git.enable = mkDefault true;
      starship.enable = cfg.prompt == "starship";
      tmux.enable = mkDefault true;
    };
  };
}
