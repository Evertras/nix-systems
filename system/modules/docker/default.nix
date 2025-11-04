{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.system.docker;
in {
  options.evertras.system.docker = { enable = mkEnableOption "Enable docker"; };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ docker-credential-helpers ];

    virtualisation.docker.rootless = {
      enable = true;
      setSocketVariable = true;

      daemon.settings = { dns = [ "1.1.1.1" "8.8.8.8" ]; };
    };
  };
}

