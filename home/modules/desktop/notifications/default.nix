{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.desktop.notifications;
in {
  imports = [ ./dunst ./mako ];

  options.evertras.home.desktop.notifications = {
    enable = mkEnableOption "Notifications";

    # For now use mako for wayland, dunst for x11
    wayland = mkEnableOption "Using Wayland";

    origin = mkOption {
      type = types.str;
      default = "bottom-center";
      description = "The location of notifications on the screen";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [
        # (Future investigation: https://github.com/Sweets/tiramisu)
        libnotify
      ];

    evertras.home.desktop.notifications.mako = {
      enable = cfg.wayland;
      origin = cfg.origin;
    };

    evertras.home.desktop.notifications.dunst = {
      enable = !cfg.wayland;
      origin = cfg.origin;
    };
  };
}
