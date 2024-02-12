{ config, lib, ... }:
with lib;
let cfg = config.evertras.home.shell.pass;
in {
  options.evertras.home.shell.pass = {
    # NOTE: Currently need to bootstrap in a GPG key,
    # figure out a nicer way to avoid juggling this later
    enable = mkEnableOption "pass";

    gpgKey = mkOption { type = types.str; };
  };

  config = {
    programs.password-store = mkIf cfg.enable {
      enable = true;

      # https://www.mankier.com/1/pass
      settings = {
        PASSWORD_STORE_KEY = cfg.gpgKey;
        EDITOR = "nvim";
      };
    };
  };
}
