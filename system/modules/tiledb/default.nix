{ config, everlib, lib, ... }:
with lib;
let cfg = config.evertras.dev.tiledb;
in {
  imports = everlib.allSubdirs ./.;

  options.evertras.dev.tiledb = {
    enable = mkEnableOption
      "System settings for developing TileDB and surrounding infrastructure";
  };

  config = mkIf cfg.enable {
    networking.wg-quick.interfaces = {
      tiledb = {
        autostart = false;
        address = [ "10.100.0.50" ];
        dns = [ "10.20.0.2" ];
        privateKeyFile = "/home/evertras/.config/wireguard/privatekey";

        peers = [{
          publicKey = "7+yFrmQ/+R4zOiIHJnHtlq9cZBoz67GRVNeTzWj0Rlw=";
          allowedIPs = [ "10.0.0.0/8" ];
          endpoint = "wg-prod.tiledb.io:51820";
          persistentKeepalive = 15;
        }];
      };
    };

    programs.nix-ld = { enable = true; };
  };
}
