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

      # Loosens reverse-path filtering so traffic to subnet routes advertised
      # in the tailnet (e.g. the demo UIs on 10.60.x) isn't dropped.
      useRoutingFeatures = "client";
    };

    environment.systemPackages = [
      # Without resolved, don't let MagicDNS take over resolv.conf, it fights
      # with the wireguard VPN's DNS via openresolv.  With resolved, tailscale
      # gets its own link and MagicDNS is safe.  Accept subnet routes so the
      # tailnet's advertised subnets (e.g. the demo UIs on 10.60.x) are
      # reachable.  These live here rather than in services.tailscale's
      # extraUpFlags, which only applies to autoconnect with an authKeyFile.
      (pkgs.writeShellApplication {
        name = "tailscale-up";
        text =
          if config.services.resolved.enable then
            ''
              args=(--accept-routes "$@")

              echo "tailscale-up: --accept-routes     use subnet routes advertised in the tailnet (e.g. demo UIs on 10.60.x)"
              echo "tailscale-up: running: sudo tailscale up ''${args[*]}"

              sudo tailscale up "''${args[@]}"
            ''
          else
            ''
              args=(--accept-dns=false --accept-routes "$@")

              echo "tailscale-up: --accept-dns=false  keep MagicDNS out of resolv.conf (avoids fighting the wireguard VPN's DNS)"
              echo "tailscale-up: --accept-routes     use subnet routes advertised in the tailnet (e.g. demo UIs on 10.60.x)"
              echo "tailscale-up: running: sudo tailscale up ''${args[*]}"

              sudo tailscale up "''${args[@]}"
            '';
      })
    ];
  };
}
