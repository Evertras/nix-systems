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

        aws-vault
        _1password-cli
      ];

      file = {
        ".evertras/shells/tiledb/shell.nix".text =
          builtins.readFile ./devshell/shell.nix;
      };
    };

    # Harmless if we're not using it anyway
    programs.waybar.settings.mainBar = {
      "custom/vpn" = {
        exec = "tdb-vpn-status";
        on-click = "tdb-vpn-toggle";
        interval = 5;
      };
    };

    evertras.home.shell.funcs = let awsSessionDuration = "12h";
    in {
      "tdb-shell".body = ''
        set -x
        nix-shell "$HOME/${shellPath}" --command fish
      '';

      "tdb-aws-sandbox".body = ''
        aws-vault exec sandbox --backend=pass --duration ${awsSessionDuration}
      '';

      "tdb-vpn-connect".body = ''
        sudo systemctl start wg-quick-tiledb
        notify-send "VPN Connected" -t 2000
      '';

      "tdb-vpn-disconnect".body = ''
        sudo systemctl stop wg-quick-tiledb
        notify-send "VPN Disconnected" -t 2000
      '';

      "tdb-vpn-toggle".body = ''
        if ip addr show tiledb &>/dev/null; then
          tdb-vpn-disconnect
        else
          tdb-vpn-connect
        fi
      '';

      "tdb-vpn-status".body = ''
        if ip addr show tiledb &>/dev/null; then
          echo 'Y'
        else
          echo 'N'
        fi
      '';

      # Keeping this as reference
      "tdb-check-vpn-config".body = ''
        if [[ ! -f ~/.config/wireguard/privatekey ]]; then
          echo 'Key not found. Run the following:'
          echo '>'
          echo 'mkdir -p ~/.config/wireguard'
          echo 'cd ~/.config/wireguard'
          echo 'wg genkey | tee privatekey | wg pubkey > publickey'
          echo 'chmod -R 600 ~/.config/wireguard/*'
          exit 1
        fi
      '';
    };
  });
}
