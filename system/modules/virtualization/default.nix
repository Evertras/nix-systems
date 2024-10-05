{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.system.virtualization;
in {
  options.evertras.system.virtualization = {
    enable = mkEnableOption "Enable virtualization";
  };

  config = mkIf cfg.enable {
    # https://nixos.wiki/wiki/Virt-manager
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;

    environment.systemPackages = with pkgs; [
      # https://wiki.nixos.org/wiki/QEMU
      qemu

      # https://github.com/kubernetes/minikube/issues/6023#issuecomment-2103782263
      docker-machine-kvm2
    ];

    # Enable other architectures for qemu
    boot.binfmt.emulatedSystems = [ "aarch64-linux" "riscv64-linux" ];
  };
}
