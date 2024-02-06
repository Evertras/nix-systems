{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.system.services.grafana;
in {
  options.evertras.system.services.grafana = {
    enable = mkEnableOption "Grafana";

    httpPort = mkOption {
      type = types.int;
      default = 3000;
      description = "The port to run Grafana on";
    };
  };

  config = mkIf cfg.enable {
    services.grafana = {
      enable = true;

      settings = {
        server = { "http_port" = cfg.httpPort; };

        auth = { "anonymous.enabled" = true; };
      };
    };
  };
}
