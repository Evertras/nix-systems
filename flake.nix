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
    ever-quickview.url = "github:Evertras/quickview";
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
                "steam"
                "steam-original"
                "steam-run"
              ];

            permittedInsecurePackages = [ "electron-25.9.0" ];
          };

          overlays = [
            (_: _: {
              cynomys = inputs.ever-cyn.packages.${system}.default;
              quickview = inputs.ever-quickview.packages.${system}.default;
            })
          ];
        });

      # My stuff
      everlib = import ./shared/everlib { inherit lib; };
      mkNerdfonts = pkgs: (import ./shared/nerdfonts { inherit pkgs; });

      # Helper to turn ./thing/someprofile.nix -> someprofile
      nameFromNixFile = file: lib.strings.removeSuffix ".nix" (baseNameOf file);
    in {
      nixosConfigurations = let
        # Make a system for every directory in ./system/machines
        #
        # Each subdirectory must contain a default.nix which
        # has the "system" and "module" attributes, where "system"
        # is the system to use and "module" is the home-manager
        # module file to use (probably a home.nix in the directory)
        machineDirs = everlib.allSubdirs ./system/machines;
        mkConfig = dir:
          (let
            userData = import dir;
            system = userData.system;
            pkgs = mkPkgs system;
            nerdfonts = mkNerdfonts pkgs;
          in lib.nixosSystem {
            inherit pkgs system;
            modules = [ userData.module ];
            specialArgs = { inherit everlib nerdfonts; };
          });
      in (builtins.listToAttrs (map (dir: {
        name = builtins.baseNameOf dir;
        value = mkConfig dir;
      }) machineDirs));

      homeConfigurations = let
        # Make a profile for every subdir in ./home/users
        #
        # Each subdirectory must contain a default.nix which
        # has the "system" and "module" attributes, where "system"
        # is the system to use and "module" is the home-manager
        # module file to use (probably a home.nix in the directory)
        userDirs = everlib.allSubdirs ./home/users;

        mkConfig = dir:
          (let
            userData = import dir;
            pkgs = mkPkgs userData.system;
            nerdfonts = mkNerdfonts pkgs;
          in home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [ nixvim.homeManagerModules.nixvim userData.module ];
            extraSpecialArgs = { inherit everlib nerdfonts; };
          });
      in (builtins.listToAttrs (map (file: {
        name = nameFromNixFile file;
        value = mkConfig file;
      }) userDirs));
    };
}
