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

  services = {
    # https://mynixos.com/nixpkgs/options/services.nomad
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
}

