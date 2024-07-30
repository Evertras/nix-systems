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

  imports = [ ./aws.nix ./common.nix ./git.nix ./mullvad.nix ./themes.nix ];

  config = let
    definedFuncs = config.evertras.home.shell.funcs;
    mkShellFunc = name: func:
      (pkgs.writeShellApplication {
        inherit name;
        runtimeInputs = func.runtimeInputs or [ ];
        text = func.body;
      });
    apps = attrsets.mapAttrsToList mkShellFunc definedFuncs;
  in { home.packages = apps; };
}
