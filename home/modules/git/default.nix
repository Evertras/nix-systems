{ config, lib, ... }:
with lib;
let cfg = config.evertras.home.git;
in {
  options.evertras.home.git = {
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
      type = types.str;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;

      userEmail = cfg.userEmail;
      userName = cfg.userName;

      signing = if cfg.gpgKey != "" then {
        signByDefault = true;
        key = cfg.gpgKey;
      } else
        null;

      extraConfig = { init = { defaultBranch = "main"; }; };
    };
  };
}
