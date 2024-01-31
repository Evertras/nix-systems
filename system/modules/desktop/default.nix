{ config, lib, ... }:
with lib;
let cfg = config.evertras.desktop;
in {
  imports = [ ./core ./i3 ../../../shared/themes/select.nix ];

  options.evertras.desktop = { enable = mkEnableOption "desktop"; };

  config = mkIf cfg.enable { evertras.desktop.core.enable = true; };
}
