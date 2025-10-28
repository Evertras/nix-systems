{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.desktop.notifications.mako;
  theme = config.evertras.themes.selected;
in {
  options.evertras.home.desktop.notifications.mako = {
    enable = mkEnableOption "Mako";

    origin = mkOption {
      type = types.str;
      default = "bottom-center";
      description = "The location of notifications on the screen";
    };
  };

  config = mkIf cfg.enable {
    services.mako = {
      enable = true;

      # https://github.com/emersion/mako/blob/master/doc/mako.5.scd
      settings = {
        actions = true;
        anchor = cfg.origin;
        background-color = theme.colors.background;
        border-color = theme.colors.primary;
        icons = true;
        font = "${theme.fonts.desktop.name} 12";
        progress-color = theme.colors.darker;
        text-color = theme.colors.text;

        "mode=do-not-disturb" = { invisible = true; };

        "urgency=critical" = {
          background-color = theme.colors.urgent;
          border-color = theme.colors.urgent;
          text-color = theme.colors.background;
        };
      };
    };
  };
}
