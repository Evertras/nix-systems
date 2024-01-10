{ config, lib, ... }:
with lib;
let cfg = config.evertras.desktop;
in {
  imports = [ ./core ./dwm ./i3 ../../../themes/select.nix ];

  options.evertras.desktop = { enable = mkEnableOption "desktop"; };

  config = mkIf cfg.enable { evertras.desktop.core.enable = true; };
}
