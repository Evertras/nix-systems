{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.desktop.notifications;
  theme = config.evertras.themes.selected;
in {
  options.evertras.home.desktop.notifications = {
    enable = mkEnableOption "notifications";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [
        # (Future investigation: https://github.com/Sweets/tiramisu)
        libnotify
      ];

    services.dunst = {
      enable = true;
      # TODO:
      # iconTheme = theme.iconTheme;
    };
  };
}
