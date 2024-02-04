# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
  themes = import ../../../shared/themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Green"; };
in {
  imports = [ ../../modules ];

  ##############################################################################
  # VM hackery
  users.users.evertras.initialPassword = "evertras";

  ##############################################################################
  # Boot stuff

  # TODO: Needed?
  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 2;
  };

  ##############################################################################
  # General system environment stuff
  time = {
    timeZone = "Asia/Tokyo";

    # Need this for dual-booting with Windows
    # https://nixos.wiki/wiki/Dual_Booting_NixOS_and_Windows
    hardwareClockInLocalTime = true;
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  console = { keyMap = "jp106"; };

  evertras.system.virtualization.enable = true;

  ##############################################################################
  # Desktop stuff
  evertras.themes.selected = theme;

  evertras.desktop = {
    enable = true;

    xserver.enable = false;
    xserver.kbLayout = "jp";

    # TODO: Specify possible sessions here (i3, dwm)
    # which are defined in home-manager
  };

  services.xserver.displayManager.autoLogin.user = "evertras";

  # Needed?
  # https://wiki.hyprland.org/Nix/Hyprland-on-NixOS/
  programs.hyprland.enable = true;

  ##############################################################################
  # Sound stuff

  # https://nixos.wiki/wiki/PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # https://nixos.wiki/wiki/Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      # Enable A2DP sink
      General.Enable = "Source,Sink,Media,Socket";
    };
  };

  ##############################################################################
  # Networking stuff

  networking = { hostName = "nixbox-playground"; };

  # TODO: Doing this because local DNS doesn't work, investigate
  networking.nameservers = [ "8.8.8.8" ];
  services.resolved = {
    enable = true;
    fallbackDns = [ "8.8.8.8" ];
  };

  ##############################################################################
  # Nvidia stuff
  # https://nixos.wiki/wiki/Nvidia
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    # Experimental stuff, turn off
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    open = false;

    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";

      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      #sync.enable = true;
    };
  };

  ##############################################################################
  # Other system-wide packages/programs
  # Keep this minimal, use home-manager for most things

  environment.systemPackages = with pkgs; [
    home-manager

    # Some handy things used while root, try to keep this minimal
    file
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?
}

