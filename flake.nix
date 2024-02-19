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

    # Extra packages here (can't put these in another file, see
    # https://github.com/NixOS/nix/issues/4945 for info)
    ever-cyn.url = "github:Evertras/cynomys";
  };

  outputs = { nixpkgs, home-manager, nixvim, ... }@inputs:
    let
      # Nix stuff
      lib = nixpkgs.lib;
      mkPkgs = system:
        (import nixpkgs {
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

          overlays = [
            (_: _: { cynomys = inputs.ever-cyn.packages.${system}.default; })
          ];
        });

      # My stuff
      everlib = import ./shared/everlib { inherit lib; };

      # Helper to turn ./thing/someprofile.nix -> someprofile
      nameFromNixFile = file: lib.strings.removeSuffix ".nix" (baseNameOf file);
    in {
      nixosConfigurations = let
        # Make a system for every directory in ./system/machines
        machineDirs = everlib.allSubdirs ./system/machines;
        system = "x86_64-linux";
        pkgs = mkPkgs system;
        nerdfonts = import ./shared/nerdfonts { inherit pkgs; };
        mkConfig = dir:
          (lib.nixosSystem {
            inherit pkgs system;
            modules = [ dir ];
            specialArgs = { inherit everlib nerdfonts; };
          });
      in (builtins.listToAttrs (map (dir: {
        name = builtins.baseNameOf dir;
        value = mkConfig dir;
      }) machineDirs));

      homeConfigurations = let
        # Make a profile for every file in ./home/users
        userFiles = everlib.allNixFiles ./home/users;

        pkgs = mkPkgs "x86_64-linux";
        nerdfonts = import ./shared/nerdfonts { inherit pkgs; };

        mkConfig = file:
          (home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [ nixvim.homeManagerModules.nixvim file ];
            extraSpecialArgs = { inherit everlib nerdfonts; };
          });
      in (builtins.listToAttrs (map (file: {
        name = nameFromNixFile file;
        value = mkConfig file;
      }) userFiles));
    };
}
