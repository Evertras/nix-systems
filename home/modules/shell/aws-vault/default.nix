{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.evertras.home.shell.aws-vault;
in
{
  options.evertras.home.shell.aws-vault = {
    # Uses pass as the backend, so this needs a GPG key for pass
    enable = mkEnableOption "aws-vault";

    passPrefix = mkOption {
      type = types.str;
      default = "aws-vault";
      description = "Directory in the password store to keep aws-vault entries under";
    };

    sessionTTL = mkOption {
      type = types.str;
      default = "12h";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ pkgs.aws-vault ];

      # https://github.com/99designs/aws-vault/blob/master/USAGE.md#environment-variables
      sessionVariables = {
        AWS_VAULT_BACKEND = "pass";
        AWS_VAULT_PASS_PREFIX = cfg.passPrefix;
        AWS_SESSION_TOKEN_TTL = cfg.sessionTTL;
      };
    };

    evertras.home.shell.pass.enable = true;
  };
}
