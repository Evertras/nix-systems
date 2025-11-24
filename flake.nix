{
  description = "My systems";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";

    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl.url = "github:nix-community/nixGL";

    # For specific python packages, because sometimes installing
    # via mise/asdf fails and it's just easier...
    nixpkgs-python.url = "github:cachix/nixpkgs-python";

    # For a rabbit hole: https://github.com/nix-community/NUR
    # nurpkgs.url = "github:nix-community/NUR";

    # Extra packages here (can't put these in another file, see
    # https://github.com/NixOS/nix/issues/4945 for info)
    ever-cyn.url = "github:Evertras/cynomys";
    ever-quickview.url = "github:Evertras/quickview";

    # Private stuff - run `nix flake update ever-tdb` etc to update
    ever-fonts.url = "git+ssh://git@github.com/Evertras/nix-fonts";
    ever-tdb.url = "git+ssh://git@github.com/Evertras/nix-tdb";
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, nixvim, nixgl
    , nixpkgs-python, ever-tdb, ... }@inputs:
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
                "1password"
                "1password-cli"
                "discord"
                "nvidia-settings"
                "nvidia-x11"
                "obsidian"
                "packer"
                "slack"
                "steam"
                "steam-original"
                "steam-run"
                "steam-unwrapped"
                "terraform"
                "vagrant"
                "vscode"
              ];

            permittedInsecurePackages = [ "electron-25.9.0" ];
          };

          overlays = [
            (_: _: {
              cynomys = inputs.ever-cyn.packages.${system}.default;
              quickview = inputs.ever-quickview.packages.${system}.default;
              everfont-berkeley = inputs.ever-fonts.packages.${system}.berkeley;
              everfont-berkeley-dashed =
                inputs.ever-fonts.packages.${system}.berkeley-dashed;

              # Version select with pythonversion."1.2.3"
              pythonversion = nixpkgs-python.packages.${system};

              # Allow access to some unstable packages for updates
              unstable = import nixpkgs-unstable { inherit system; };
            })

            nixgl.overlay
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
            modules = [ userData.module ever-tdb.mkSystemModule ];
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
            modules = [
              nixvim.homeModules.nixvim
              userData.module
              ever-tdb.mkHomeModule
            ];
            extraSpecialArgs = { inherit everlib nerdfonts; };
          });
      in (builtins.listToAttrs (map (file: {
        name = nameFromNixFile file;
        value = mkConfig file;
      }) userDirs));
    };
}
