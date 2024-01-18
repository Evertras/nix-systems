{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.shell.spotify;
in {
  options.evertras.home.shell.spotify = {
    enable = mkEnableOption "spotify (terminal/systemd)";

    # https://docs.spotifyd.rs/config/File.html
    device-name = mkOption {
      type = types.str;
      default = "nixbox";
    };

    device-type = mkOption {
      type = types.str;
      default = "computer";
    };
  };

  config = mkIf cfg.enable {
    services.spotifyd = {
      enable = true;

      settings.global = {
        username = "bfullj@gmail.com";
        password_cmd = "${pkgs.pass}/bin/pass spotify";
        device_name = cfg.device-name;
        device_type = "computer";
      };
    };

    home.packages = [
      # Binary is 'spt'
      pkgs.spotify-tui
    ];
  };
}
