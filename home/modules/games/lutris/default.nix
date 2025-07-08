# https://nixos.wiki/wiki/Lutris
{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.games.lutris;
in {
  options.evertras.home.games.lutris = { enable = mkEnableOption "Lutris"; };

  config = let
    lutrisPkg = (pkgs.lutris.override {
      # Add extra package deps here later, for reference
      extraPkgs = pkgs: [ ];
    });
  in mkIf cfg.enable {
    evertras.home.shell.funcs = {
      lutris-launch = {
        runtimeInputs = [ lutrisPkg ];
        body = ''
          # Gets around protobuf missing issue so we can use battle.net
          # https://github.com/lutris/lutris/issues/5330
          PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python nvidia-offload lutris
        '';
      };
    };

    home.packages = [ lutrisPkg pkgs.wine ];
  };
}
