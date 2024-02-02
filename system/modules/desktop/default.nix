{ config, everlib, lib, ... }:
with lib;
let cfg = config.evertras.desktop;
in {
  imports = (everlib.allSubdirs ./.) ++ [ ../../../shared/themes/select.nix ];

  options.evertras.desktop = { enable = mkEnableOption "desktop"; };

  config = mkIf cfg.enable { evertras.desktop.xserver.enable = true; };
}
