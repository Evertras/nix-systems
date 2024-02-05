{ lib, ... }:
with lib;
let cfg = options.evertras.system.virtualization;
in {
  options.evertras.system.virtualization = {
    enable = mkEnableOption "Enable virtualization";
  };

  config = mkIf cfg.enable {
    # https://nixos.wiki/wiki/Virt-manager
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
  };
}
