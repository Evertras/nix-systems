{ config, pkgs, lib, ... }:
with lib;
let cfg = config.evertras.home.desktop.discord;
in {
  options.evertras.home.desktop.discord = {
    enable = mkEnableOption "discord";
  };

  config = mkIf cfg.enable { home.packages = with pkgs; [ discord ]; };
}
