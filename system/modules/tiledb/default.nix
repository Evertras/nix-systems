{ config, everlib, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.dev.tiledb;
in {
  imports = everlib.allSubdirs ./.;

  options.evertras.dev.tiledb = {
    enable = mkEnableOption
      "Environment settings for developing TileDB and surrounding infrastructure";
  };

  # Prefer putting things in home manager for ease of use, but some things seem to only want to work here...
  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        # Build tools
        cmake
        pkg-config
        vcpkg

        # Recent python, exact version unimportant
        python312

        # VPN tooling
        wireguard-tools
      ];

      # Development vars
      variables = let
        # Skipping $XDG_DATA_HOME because it doesn't seem to be set in time... cheating for now
        tiledb-home-dir = "$HOME/.local/share/tiledb";
      in {
        CGO_CFLAGS = "-I${tiledb-home-dir}/include";
        CGO_LDFLAGS = "-L${tiledb-home-dir}/lib64";
        TILEDB_HOME = tiledb-home-dir;
        TILEDB_PATH = tiledb-home-dir;
        TILEDB_DEV_DATA = "${tiledb-home-dir}/devdata";
      };
    };

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
