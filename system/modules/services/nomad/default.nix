{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.system.services.nomad;
in {
  options.evertras.system.services.nomad = {
    enable = lib.mkEnableOption "single node nomad sandbox";
  };

  config = mkIf cfg.enable {
    # https://mynixos.com/nixpkgs/options/services.nomad
    services = {
      nomad = {
        enable = true;

        # Nomad settings can be generated/templated here
        settings = {
          data_dir = "/var/lib/nomad";

          client = {
            enabled = true;
            servers = [ "localhost" ];
          };

          server = {
            enabled = true;
            bootstrap_expect = 1;
          };
        };
      };
    };
  };
}
