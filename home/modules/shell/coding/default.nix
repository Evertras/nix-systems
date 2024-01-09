{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.shell.coding;
in {
  options.evertras.home.shell.coding = {
    go = { enable = mkEnableOption "golang"; };
    python = { enable = mkEnableOption "python"; };
    rust = { enable = mkEnableOption "rust"; };
    nodejs = { enable = mkEnableOption "nodejs"; };
  };

  config = with pkgs; {
    home.packages = let
      genPkgs = enabled: pkgList: if enabled then pkgList else [ ];

      pkgList = lists.flatten [
        (genPkgs cfg.go.enable [ go ])
        (genPkgs cfg.python.enable [ python3 ])
        (genPkgs cfg.rust.enable [ cargo rustc ])
        (genPkgs cfg.nodejs.enable [ nodejs_21 ])
      ];
    in pkgList;
  };
}
