{ config, lib, pkgs, ... }:
with lib; {
  options.evertras.home.shell.funcs = mkOption {
    description = ''
      Key is the function name.  Value is:

      {
        # Required
        body = "echo hi";
      }
    '';
    type = with types; attrsOf attrs;
    default = { };
  };

  imports = [
    ./aws.nix
    ./common.nix
    ./kubectl.nix
    ./git.nix
    ./mullvad.nix
    ./themes.nix
  ];

  config = let
    definedFuncs = config.evertras.home.shell.funcs;
    mkShellFunc = prefix: name: func:
      (pkgs.writeShellApplication {
        name = prefix + name;
        runtimeInputs = func.runtimeInputs or [ ];
        text = func.body;
      });
    mkShellBase = mkShellFunc "";
    # This makes tab completes annoying, but nice to keep as reference
    #mkShellPrefixed = mkShellFunc "evertras-";
    apps = attrsets.mapAttrsToList mkShellBase definedFuncs;
    #appsPrefixed = attrsets.mapAttrsToList mkShellPrefixed definedFuncs;
    #in { home.packages = apps ++ appsPrefixed; };
  in { home.packages = apps; };
}
