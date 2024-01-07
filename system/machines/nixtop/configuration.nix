# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ pkgs, ... }:

{
  imports = [
    ../../modules

    ./hardware-configuration.nix
  ];

  evertras.desktop.i3.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.xserver.displayManager.autoLogin.user = "evertras";

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

  # Networking stuff
  networking = {
    hostName = "nixtop";
    wireless = {
      # Enables wireless support via wpa_supplicant.
      enable = true;
      networks = {
        GenjiNet = {
          # https://nixos.wiki/wiki/Wpa_supplicant
          # Encrypted, and if you crack it then I guess you can
          # drive by my house somewhere and watch Netflix?
          pskRaw =
            "b8dd5632220c928a1bb44fc846fe1cf3b4b27dd32db104640c3ec30e8020a9b4";
        };
      };
    };
  };

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";

  console = { keyMap = "jp106"; };

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [
    home-manager

    # Some handy things used while root, try to keep this minimal
    file
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # TODO: Doing this because local DNS doesn't work, investigate
  networking.nameservers = [ "8.8.8.8" ];
  services.resolved = {
    enable = true;
    fallbackDns = [ "8.8.8.8" ];
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

