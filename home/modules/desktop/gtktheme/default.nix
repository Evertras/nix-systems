{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.desktop.gtktheme;
  theme = config.evertras.themes.selected;
  cursorTheme = {
    name = if cfg.cursor.name == null then
      theme.cursorTheme.name
    else
      cfg.cursor.name;
    package = if cfg.cursor.package == null then
      pkgs.${theme.cursorTheme.packageName}.${theme.cursorTheme.packageOutput}
    else
      cfg.cursor.package;
    size = cfg.cursor.size;
  };
  font = {
    # TODO: Cleaner null check, but 'or' doesn't work...
    name =
      if cfg.font.name == null then theme.fonts.desktop.name else cfg.font.name;
    package = cfg.font.package;
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

    font = {
      name = mkOption {
        description = ''
          Override the selected Evertras theme font.
        '';
        type = with types; nullOr str;
        default = null;
      };

      package = mkOption {
        type = types.package;
        default = pkgs.nerdfonts;
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
    home.pointerCursor = cursorTheme;
    gtk = {
      enable = true;

      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };

      theme = {
        name = if cfg.overall.name == null then
          theme.gtkTheme.name
        else
          cfg.overall.name;
        package = if cfg.overall.package == null then
          pkgs.${theme.gtkTheme.packageName}
        else
          cfg.overall.package;
      };

      inherit cursorTheme;

      inherit font;

      gtk3.extraConfig = {
        Settings = ''
          gtk-application-prefer-dark-theme=1
        '';
      };

      gtk4.extraConfig = {
        Settings = ''
          gtk-application-prefer-dark-theme=1
        '';
      };
    };
  };
}
