{ config, everlib, lib, ... }:
with everlib;
with lib;
let
  cfg = config.evertras.home.desktop.terminals.alacritty;
  theme = config.evertras.themes.selected;
in {
  options.evertras.home.desktop.terminals.alacritty = {
    enable = mkEnableOption "alacritty";

    fontName = mkOption {
      type = with types; nullOr str;
      default = null;
    };

    fontSize = mkOption {
      type = types.int;
      default = 10;
    };

    opacity = mkOption {
      type = with types; nullOr str;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        window = {
          decorations = "none";
          opacity = 0.8;
          startup_mode = "Maximized";
        };

        font = {
          normal.family = existsOr cfg.fontName theme.fonts.terminal.name;
          size = cfg.fontSize;
        };

        live_config_reload = true;

        mouse = { hide_when_typing = true; };
      };
    };
  };
}
