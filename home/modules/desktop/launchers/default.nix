{ config, everlib, lib, ... }:
with lib;
with everlib;
let cfg = config.evertras.home.desktop.launchers;
in {
  imports = allSubdirs ./.;

  options.evertras.home.desktop.launchers = {
    enable = mkEnableOption "Enable default launcher func";

    defaultLauncher = mkOption {
      type = types.str;
      default = "tofi";
    };
  };

  config = mkIf cfg.enable {
    evertras.home.desktop.launchers = {
      tofi.enable = mkDefault (cfg.defaultLauncher == "tofi");
    };

    evertras.home.shell.funcs = {
      # Default app launcher
      launch-app = let launchFuncs = { tofi = "launch-app-tofi-fullscreen"; };
      in { body = launchFuncs.${cfg.defaultLauncher}; };
    };
  };
}
