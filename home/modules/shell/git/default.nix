{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.shell.git;
in {
  options.evertras.home.shell.git = {
    enable = mkEnableOption "git";

    userEmail = mkOption {
      type = types.str;
      default = "bfullj@gmail.com";
    };

    userName = mkOption {
      type = types.str;
      default = "Brandon Fulljames";
    };

    gpgKey = mkOption {
      type = with types; nullOr str;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      # Don't need this often, but useful to have when needed
      pkgs.git-filter-repo
    ];

    programs.git = {
      enable = true;

      userEmail = cfg.userEmail;
      userName = cfg.userName;

      lfs.enable = true;

      signing = if cfg.gpgKey != null then {
        signByDefault = true;
        key = cfg.gpgKey;
      } else
        null;

      extraConfig.init.defaultBranch = "main";
    };
  };
}
