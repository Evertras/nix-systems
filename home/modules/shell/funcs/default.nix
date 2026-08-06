{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.evertras.home.shell = {
    funcs = mkOption {
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

    funcPackages = mkOption {
      description = ''
        The built package for each defined func, keyed by func name.

        Set automatically from funcs, so no default here - a default would
        count as a second definition and trip readOnly.  Reference these when
        something needs a real store path instead of relying on the func being
        on PATH, such as a systemd unit's ExecStart.
      '';
      type = with types; attrsOf package;
      readOnly = true;
    };
  };

  imports = [
    ./aws.nix
    ./claude.nix
    ./common.nix
    ./kubectl.nix
    ./git.nix
    ./mullvad.nix
    ./sops.nix
    ./themes.nix
  ];

  config =
    let
      definedFuncs = config.evertras.home.shell.funcs;
      mkShellFunc =
        prefix: name: func:
        (pkgs.writeShellApplication {
          name = prefix + name;
          runtimeInputs = func.runtimeInputs or [ ];
          text = func.body;
        });
      mkShellBase = mkShellFunc "";
      # This makes tab completes annoying, but nice to keep as reference
      #mkShellPrefixed = mkShellFunc "evertras-";
    in
    {
      evertras.home.shell.funcPackages = attrsets.mapAttrs mkShellBase definedFuncs;

      home.packages = attrsets.attrValues config.evertras.home.shell.funcPackages;
    };
}
