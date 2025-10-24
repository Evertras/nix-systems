{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.shell.dashlane;
in {
  options.evertras.home.shell.dashlane = {
    enable = mkEnableOption "Dashlane CLI";
  };

  config = mkIf cfg.enable {
    # TODO: I can't figure out how to properly install this, keep getting weird
    # pkg errors when running it from nix store...
    evertras.home.shell.funcs.install-dcli.body = ''
      mkdir -p ~/.evertras/bin
      curl -o ~/.evertras/bin/dcli -L "https://github.com/Dashlane/dashlane-cli/releases/download/v6.2526.2/dcli-linux-x64"
      chmod +x ~/.evertras/bin/dcli
    '';
  };
}
