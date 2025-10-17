{ config, everlib, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.tiledb;
in {
  imports = everlib.allSubdirs ./.;

  options.evertras.home.tiledb = {
    enable = mkEnableOption
      "Environment settings for developing TileDB and surrounding infrastructure";
  };

  # Prefer putting things here instead of system when possible, but some things want to be in system
  # in order to build properly. Unsure why, too little time to figure it out further for now.
  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        # Minio stuff - could do this with Docker but easy enough to have it here
        minio
        minio-client

        # Needed by Server
        zstd
      ];
    };
  };
}
