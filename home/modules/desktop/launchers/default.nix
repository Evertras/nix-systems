{ config, everlib, lib, pkgs, ... }:
with lib;
with everlib;
let cfg = config.evertras.home.desktop.launchers;
in {

  imports = everlib.allSubdirs ./.;
  options.evertras.home.desktop.launchers = {
    enable = mkEnableOption "Enable default launcher func";

    defaultLauncher = mkOption {
      type = types.str;
      default = "tofi";
    };
  };

  config = {
    evertras.home.desktop.launchers = {
      tofi.enable = mkDefault (cfg.defaultLauncher == "tofi");
    };

    evertras.home.shell.funcs = mkIf cfg.enable {
      # Default app launcher
      launch-app = let launchFuncs = { tofi = "launch-app-tofi-fullscreen"; };
      in { body = launchFuncs.${cfg.defaultLauncher}; };
    };
  };
}
