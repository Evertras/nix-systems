{ config, lib, ... }:
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

  config.evertras.home.shell = {
    bash.enable = cfg.shell == "bash";
    editorconfig.enable = mkDefault true;
    git.enable = mkDefault true;
    starship.enable = cfg.prompt == "starship";
    tmux.enable = mkDefault true;
  };
}
