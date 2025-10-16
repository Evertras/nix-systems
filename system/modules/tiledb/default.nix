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
    environment = {
      systemPackages = with pkgs; [
        # Build tools
        cmake
        pkg-config
        vcpkg
      ];

      # Development vars
      variables = let
        # Skipping $XDG_DATA_HOME because it doesn't seem to be set in time... cheating for now
        tiledb-home-dir = "$HOME/.local/share/tiledb";
      in {
        TILEDB_HOME = tiledb-home-dir;
        TILEDB_DEV_DATA = "${tiledb-home-dir}/devdata";
        LD_LIBRARY_PATH = "${tiledb-home-dir}/lib:\${LD_LIBRARY_PATH}";
        CGO_CFLAGS = "-I${tiledb-home-dir}/include";
        CGO_LDFLAGS = "-L${tiledb-home-dir}/lib";
      };
    };

    programs.nix-ld = { enable = true; };
  };
}
