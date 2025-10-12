{ config, everlib, pkgs, lib, ... }:
with lib;
let cfg = config.evertras.home.desktop.browsers;
in {
  imports = everlib.allSubdirs ./.;

  options.evertras.home.desktop.browsers = {
    enableLibrewolf = mkOption {
      type = types.bool;
      default = true;
      description = "enable librewolf";
    };

    enableFirefox = mkOption {
      type = types.bool;
      default = false;
      description = "enable firefox";
    };

    enableChromium = mkOption {
      type = types.bool;
      default = false;
      description = "enable chromium";
    };

    default = mkOption {
      type = types.str;
      default = "librewolf";
    };
  };

  config = let
    pkgsLibrewolf =
      if cfg.enableLibrewolf then [ pkgs.unstable.librewolf ] else [ ];
    pkgsChromium = if cfg.enableChromium then [ pkgs.chromium ] else [ ];
    pkgsFirefox = if cfg.enableFirefox then [ pkgs.firefox ] else [ ];
  in { home.packages = pkgsLibrewolf ++ pkgsChromium ++ pkgsFirefox; };
}
