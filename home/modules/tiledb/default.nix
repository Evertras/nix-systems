{ config, everlib, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.tiledb;
in {
  imports = everlib.allSubdirs ./.;

  options.evertras.home.tiledb = {
    enable = mkEnableOption
      "Environment settings for developing TileDB and surrounding infrastructure";
  };

  # Prefer putting things here instead of system when possible, but some things want to be in system
  # in order to build properly. Unsure why, too little time to figure it out further for now.
  config = mkIf cfg.enable (let shellPath = ".evertras/shells/tiledb";
  in {
    home = {
      packages = with pkgs; [
        # Minio stuff - could do this with Docker but easy enough to have it here
        minio
        minio-client

        # Needed by Server
        zstd
      ];

      file = {
        ".evertras/shells/tiledb/shell.nix".text =
          builtins.readFile ./devshell/shell.nix;
      };
    };

    evertras.home.shell.funcs = {
      "ndft".body = ''
        set -x
        nix-shell "$HOME/${shellPath}" --command fish
      '';

      # Need to generate a keypair first, keep this manual...
      # don't script the generation since it's one time only,
      # and I don't want to accidentally overwrite it.
      "generate-vpn-config".body = ''
        if [[ ! -f ~/.config/wireguard/privatekey ]]; then
          echo 'Key not found. Run the following:'
          echo '>'
          echo 'mkdir -p ~/.config/wireguard'
          echo 'cd ~/.config/wireguard'
          echo 'wg genkey | tee privatekey | wg pubkey > publickey'
          echo 'chmod -R 600 ~/.config/wireguard/*'
          exit 1
        fi

        cat <<EOF > ~/.config/wireguard/tiledb-wg.conf
        [Interface]
        PrivateKey = $(cat ~/.config/wireguard/privatekey)
        Address = 10.100.0.50
        DNS = 10.20.0.2

        # Do not change anything in the below config
        [Peer]
        PublicKey = 7+yFrmQ/+R4zOiIHJnHtlq9cZBoz67GRVNeTzWj0Rlw=
        AllowedIPs = 10.0.0.0/8
        Endpoint = wg-prod.tiledb.io:51820
        PersistentKeepalive = 15
        EOF

        chmod 0600 ~/.config/wireguard/tiledb-wg.conf
      '';
    };
  });
}
