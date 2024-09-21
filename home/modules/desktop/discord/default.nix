{ config, pkgs, lib, ... }:
with lib;
let cfg = config.evertras.home.desktop.discord;
in {
  options.evertras.home.desktop.discord = {
    enable = mkEnableOption "discord";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ discord ];

    home.file = {
      ".config/discord/settings.json" = {
        text = ''
          {
            "SKIP_HOST_UPDATE": true
          }
        '';
      };
    };
  };
}
