{ config, everlib, lib, pkgs, ... }:
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
      type = types.float;
      default = 0.9;
    };

    # Omit the .toml extension
    # https://github.com/alacritty/alacritty-theme/tree/master/themes
    themeName = mkOption {
      type = types.str;
      default = "catppuccin_mocha";
    };
  };

  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        import = [ "${pkgs.alacritty-theme}/${cfg.themeName}.yaml" ];

        window = {
          decorations = "none";
          opacity = cfg.opacity;
          startup_mode = "Maximized";
        };

        font = {
          normal.family = existsOr cfg.fontName theme.fonts.terminal.name;
          size = cfg.fontSize;
        };

        key_bindings = [
          # JP Mac keyboard fix
          {
            key = "Yen";
            mods = "None";
            chars = "\\\\";
          }

          {
            key = "I";
            mods = "Shift|Control";
            action = "IncreaseFontSize";
          }

          {
            key = "O";
            mods = "Shift|Control";
            action = "DecreaseFontSize";
          }

          {
            key = "U";
            mods = "Shift|Control";
            action = "ResetFontSize";
          }
        ];

        live_config_reload = true;

        mouse = { hide_when_typing = true; };
      };
    };
  };
}
