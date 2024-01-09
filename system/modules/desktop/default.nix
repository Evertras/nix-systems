{ config, lib, ... }:
with lib;
let cfg = config.evertras.desktop;
in {
  imports = [ ./core ./dwm ./i3 ];

  options.evertras.desktop = { enable = mkEnableOption "desktop"; };

  config = { evertras.desktop.core.enable = true; };
}
