{ pkgs, lib, config, ... }:
with lib;
let cfg = config.evertras.system.vpn.mullvad;
in {
  options.evertras.system.vpn.mullvad = {
    enable = mkEnableOption "Enable Mullvad VPN";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ mullvad mullvad-vpn ];

    services.mullvad-vpn = { enable = true; };
  };
}
