{
  description = "My systems";

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
        modules = [ ./systems/vm-nixbox/configuration.nix ];
      };
    };
  };
}
