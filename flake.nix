{
  description = "2024 Windows VM NixOS Sandbox";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs, ... }:
  let
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      nixbox = lib.nixosSystem {
        system = "linux-x86_64";
        modules = [ ./configuration.nix ];
      };
    };
  };
}
