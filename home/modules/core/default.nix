# Non-negotiables that every user config must have defined
{ config, everlib, lib, ... }:
with everlib;
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

    usingNixOS = mkOption {
      description = ''
        True if using NixOS, false otherwise.  This
        can control some extra considerations needed
        when using home-manager on top of another distro.
      '';
      type = types.bool;
      default = true;
    };
  };

  config = {
    home = {
      username = cfg.username;
      homeDirectory = existsOr cfg.homeDirectory "/home/${cfg.username}";
    };

    programs = {
      # Let Home Manager install and manage itself.
      home-manager.enable = true;
    };
  };
}
