{ config, lib, ... }:
with lib; {
  options.evertras.home.shell.funcs = mkOption {
    description = ''
      Key is the function name.  Value is:

      {
        # Required
        body = "echo hi";
      }
    '';
    type = types.attrsOf types.attrs;
    default = { };
  };

  imports = [ ./aws.nix ./common.nix ./git.nix ./themes.nix ];

  config = let definedFuncs = config.evertras.home.shell.funcs;
  in {
    home.file = mapAttrs' (name: func:
      nameValuePair (".evertras/funcs/${name}") ({
        text = ''
          #!/usr/bin/env bash

          ${func.body}
        '';
        executable = true;
      })) definedFuncs;
  };
}
