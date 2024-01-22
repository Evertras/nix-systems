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
      pkgList = with lists;
        flatten [
          (optional cfg.python.enable python3)
          (optional cfg.rust.enable [ cargo rustc ])
          (optional cfg.nodejs.enable nodejs_21)
        ];
    in pkgList;

    programs.go = mkIf cfg.go.enable {
      enable = true;
      goPath = ".evertras/go";
      goBin = ".evertras/go/bin";
    };
  };
}
