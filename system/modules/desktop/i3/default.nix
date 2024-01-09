# Desktop environment
# https://nixos.wiki/wiki/I3
{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.desktop.i3;
in {
  options.evertras.desktop.i3 = { enable = mkEnableOption "i3 desktop"; };

  config = mkIf cfg.enable {
    services.xserver = {
      displayManager.defaultSession = "none+i3";

      # Only really want this so we can use the defaultSession
      # value above, this should be managed by home-manager
      windowManager.i3.enable = true;
    };
  };
}
