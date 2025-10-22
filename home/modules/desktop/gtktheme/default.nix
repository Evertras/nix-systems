{ config, everlib, lib, ... }:
with lib;
with everlib;
let
  cfg = config.evertras.home.desktop.gtktheme;
  theme = config.evertras.themes.selected;
  cursorTheme = {
    name = existsOr cfg.cursor.name theme.cursorTheme.name;
    package = existsOr cfg.cursor.package theme.cursorTheme.package;
    size = cfg.cursor.size;
  };
  font = {
    name = existsOr cfg.font.name theme.fonts.desktop.name;
    package = existsOr cfg.font.package theme.fonts.desktop.package;
    size = cfg.font.size;
  };
in {
  options.evertras.home.desktop.gtktheme = {
    enable = mkEnableOption "gtktheme";

    cursor = {
      name = mkOption {
        type = with types; nullOr str;
        default = null;
      };

      package = mkOption {
        type = with types; nullOr package;
        default = null;
      };

      size = mkOption {
        type = types.int;
        default = 32;
      };
    };

    iconTheme = {
      name = mkOption {
        type = with types; nullOr str;
        default = null;
      };

      package = mkOption {
        type = with types; nullOr package;
        default = null;
      };
    };

    font = {
      name = mkOption {
        description = ''
          Override the selected Evertras theme font.
        '';
        type = with types; nullOr str;
        default = null;
      };

      package = mkOption {
        type = with types; nullOr package;
        default = null;
      };

      size = mkOption {
        type = types.int;
        default = 12;
      };
    };

    overall = {
      name = mkOption {
        type = with types; nullOr str;
        default = null;
      };

      package = mkOption {
        type = with types; nullOr package;
        default = null;
      };
    };
  };

  config = mkIf cfg.enable {
    home.pointerCursor = cursorTheme // {
      x11 = {
        enable = true;
        defaultCursor = "default";
      };
    };

    evertras.home.shell.env.vars = {
      # Catppuccin hates GTK development... just use SOME dark theme for now.
      # https://github.com/catppuccin/gtk/issues/262
      GTK_THEME = "Adwaita:dark";
    };

    gtk = {
      enable = true;

      inherit cursorTheme font;

      iconTheme = {
        name = existsOr cfg.iconTheme.name theme.iconTheme.name;
        package = existsOr cfg.iconTheme.package theme.iconTheme.package;
      };

      theme = {
        name = existsOr cfg.overall.name theme.gtkTheme.name;
        package = existsOr cfg.overall.package cfg.overall.package;
      };

      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    };

    qt = {
      enable = true;
      style = {
        name = theme.gtkTheme.name;
        package = theme.gtkTheme.package;
      };
    };
  };
}
