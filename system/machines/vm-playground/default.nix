# This is a VM playground to try using NixOS as a server
# configuration tool.

{ config, lib, pkgs, ... }: {
  imports = [ ../../modules ./base.nix ];

  # https://mynixos.com/nixpkgs/options/virtualisation.docker
  virtualisation.docker = {
    enable = true;

    autoPrune = {
      enable = true;
      dates = "daily";
    };
  };

  evertras.system.services.nomad.enable = true;
}

