{ config, lib, ... }:
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
    programs.git = {
      enable = true;

      userEmail = cfg.userEmail;
      userName = cfg.userName;

      signing = if cfg.gpgKey != null then {
        signByDefault = true;
        key = cfg.gpgKey;
      } else
        null;

      extraConfig.init.defaultBranch = "main";
    };
  };
}
