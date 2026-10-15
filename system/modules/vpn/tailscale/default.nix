{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.evertras.system.vpn.tailscale;
in
{
  options.evertras.system.vpn.tailscale = {
    enable = mkEnableOption "Enable Tailscale";
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
    };

    environment.systemPackages = [
      # Don't let MagicDNS take over resolv.conf, it fights with the
      # wireguard VPN's DNS via openresolv
      (pkgs.writeShellApplication {
        name = "tailscale-up";
        text = ''
          sudo tailscale up --accept-dns=false "$@"
        '';
      })
    ];
  };
}
