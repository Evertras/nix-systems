{
  description = "My systems";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # For a rabbit hole: https://github.com/nix-community/NUR
    # nurpkgs.url = "github:nix-community/NUR";
  };

  outputs = { nixpkgs, home-manager, nixvim, ... }:

    let
      # Nix stuff
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;

        # Explicitly allow certain unfree software
        config = {
          allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "nvidia-settings"
              "nvidia-x11"
              "obsidian"
            ];

          permittedInsecurePackages = [ "electron-25.9.0" ];
        };
      };

      # My stuff
      everlib = import ./shared/everlib { inherit lib; };
      nerdfonts = import ./shared/nerdfonts { inherit pkgs; };
    in {
      nixosConfigurations = {
        nixbox = lib.nixosSystem {
          inherit system;
          modules = [ ./system/machines/vm-nixbox/configuration.nix ];
          specialArgs = { inherit everlib nerdfonts; };
        };

        nixtop = lib.nixosSystem {
          inherit pkgs system;
          modules = [ ./system/machines/nixtop/configuration.nix ];
          specialArgs = { inherit everlib nerdfonts; };
        };
      };

      homeConfigurations = let
        names = [ "evertras-vm" "evertras-nixtop" "work" ];

        mkConfig = name:
          (home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules =
              [ nixvim.homeManagerModules.nixvim ./home/users/${name}.nix ];
            extraSpecialArgs = { inherit everlib nerdfonts; };
          });
      in (builtins.listToAttrs (map (n: {
        name = n;
        value = mkConfig n;
      }) names));
    };
}
