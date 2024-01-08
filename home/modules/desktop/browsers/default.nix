{ config, pkgs, lib, ... }:
with lib;
let cfg = config.evertras.home.desktop.browsers;
in {
  imports = [ ./firefox ];

  options.evertras.home.desktop.browsers = {
    enableLibrewolf = mkOption {
      type = types.bool;
      default = true;
      description = "enable librewolf";
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
    pkgsLibrewolf = if cfg.enableLibrewolf then [ pkgs.librewolf ] else [ ];
    pkgsChromium = if cfg.enableChromium then [ pkgs.chromium ] else [ ];
  in { home.packages = pkgsLibrewolf ++ pkgsChromium; };
}
