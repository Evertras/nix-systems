{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.theme;
  cursorTheme = {
    name = cfg.cursor.name;
    package = cfg.cursor.package;
    size = cfg.cursor.size;
  };
in {
  options.evertras.home.theme = {
    enable = mkEnableOption "theme";

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
        name = "palenight";
        package = pkgs.palenight-theme;
      };

      inherit cursorTheme;

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
