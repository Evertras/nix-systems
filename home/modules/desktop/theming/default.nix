{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.theming;
  cursorTheme = {
    name = cfg.cursor.name;
    package = cfg.cursor.package;
    size = cfg.cursor.size;
  };
  font = {
    name = cfg.font.name;
    package = cfg.font.package;
    size = cfg.font.size;
  };
in {
  # For ideas: https://www.gnome-look.org/browse?cat=135&ord=rating
  # For names: try to follow the symbolic links in .icons after install,
  #            but it would be nice to have a better system...
  options.evertras.home.theming = {
    enable = mkEnableOption "theming";

    cursor = {
      name = mkOption {
        type = types.str;
        default = "Numix-Cursor";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.numix-cursor-theme;
      };

      size = mkOption {
        type = types.int;
        default = 12;
      };
    };

    font = {
      name = mkOption {
        type = types.str;
        default = "CaskaydiaCove Nerd Font";
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
        type = types.str;
        default = "palenight";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.palenight-theme;
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
        name = cfg.overall.name;
        package = cfg.overall.package;
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
