# Non-negotiables that every user config must have defined
{ config, lib, ... }:
with lib;
let cfg = config.evertras.home.core;
in {
  options.evertras.home.core = {
    username = mkOption { type = types.str; };

    homeDirectory = mkOption {
      description = ''
        Defaults to /home/{username}, but may need
        to override in some environments such as Darwin
      '';
      type = types.str;
      default = "";
    };
  };
  config = {
    home = {
      username = cfg.username;
      homeDirectory = if cfg.homeDirectory == "" then
        "/home/${cfg.username}"
      else
        cfg.homeDirectory;
    };

    programs = {
      # Let Home Manager install and manage itself.
      home-manager.enable = true;
    };
  };
}
