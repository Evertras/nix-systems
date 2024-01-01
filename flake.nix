{
  outputs = { self, nixpkgs, ... };
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
