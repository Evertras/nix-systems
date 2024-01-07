{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.shell.spotify;
in {
  options.evertras.home.shell.spotify = {
    enable = mkEnableOption "spotify (terminal/systemd)";
  };

  config = mkIf cfg.enable {
    services.spotifyd = {
      enable = true;

      settings.global = {
        username = "bfullj@gmail.com";
        password_cmd = "pass spotify";
        device-name = "nixtop";
        device-type = "computer";
      };
    };

    home.packages = [ pkgs.spotify-tui ];
  };
}
