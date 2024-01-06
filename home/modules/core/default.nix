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
      type = with types; nullOr str;
      default = null;
    };
  };

  config = {
    home = {
      username = cfg.username;
      homeDirectory = (import ./homedir.nix { inherit config; }).homeDir;
    };

    programs = {
      # Let Home Manager install and manage itself.
      home-manager.enable = true;
    };
  };
}
