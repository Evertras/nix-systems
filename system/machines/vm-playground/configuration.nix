# This is a VM playground to try using NixOS as a server
# configuration tool.

{ pkgs, ... }:
let
  bootstrap = pkgs.writeShellApplication {
    name = "bootstrap";
    text = ''
      mkdir -p ~/.local/state/nix/profiles
      git clone https://github.com/Evertras/simple-homemanager
    '';
  };

in {
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

  environment.systemPackages = with pkgs; [
    bootstrap
    git
    home-manager
    neovim
    gnumake
  ];
}

