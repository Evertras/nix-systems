{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.shell.minikube;
in {
  options.evertras.home.shell.minikube = {
    enable = mkEnableOption "Minikube";

    # https://minikube.sigs.k8s.io/docs/drivers/
    driver = mkOption {
      type = types.str;
      # Default is docker, but this doesn't work nicely
      # so use kvm2 - enable with evertras.system.virtualization on nixos
      default = "kvm2";
      description = "The driver to use for Minikube";
    };

    memoryMb = mkOption {
      type = types.int;
      default = 4096;
      description = "The amount of memory (in MB) to allocate to Minikube";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ kubectl minikube ];

    evertras.home.shell.env.vars = {
      MINIKUBE_DRIVER = cfg.driver;
      MINIKUBE_MEMORY = toString cfg.memoryMb;
    };

    # Quick abbreviations
    programs.fish.shellAbbrs.k = "kubectl";
  };
}
