{
  description = "My systems";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations = {
        nixbox = lib.nixosSystem {
          inherit system;
          modules = [ ./systems/vm-nixbox/configuration.nix ];
        };
      };

      homeConfigurations = {
        evertras = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/users/evertras.nix ];
        };
      };
    };
}
