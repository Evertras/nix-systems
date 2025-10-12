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
    home.packages = with pkgs; [ mako ];

    home.file = {
      # https://github.com/emersion/mako/blob/master/doc/mako.5.scd
      ".config/mako/config".text = ''
        actions=true
        anchor=${cfg.origin}
        background-color=${theme.colors.background}
        border-color=${theme.colors.primary}

        [actionable=true]
        anchor=top-left
      '';
    };
  };
}
