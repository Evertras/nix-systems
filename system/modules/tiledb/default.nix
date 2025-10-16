{ config, everlib, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.dev.tiledb;
in {
  imports = everlib.allSubdirs ./.;

  options.evertras.dev.tiledb = {
    enable = mkEnableOption
      "Environment settings for developing TileDB and surrounding infrastructure";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Build tools
      cmake
      pkg-config
      vcpkg
    ];

    programs.nix-ld = { enable = true; };
  };
}
