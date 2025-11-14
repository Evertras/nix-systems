# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }: {
  imports = [
    ../../modules

    ./hardware-configuration.nix
  ];

  ##############################################################################
  # Hardware stuff
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "ignore";
  };

  ##############################################################################
  # Boot stuff

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        # Write our own config file because there's no way
        # to write default @saved ourselves and I don't
        # want to risk switching bootloaders...
        # https://github.com/NixOS/nixpkgs/pull/286672
        extraInstallCommands = ''
          echo 'timeout 10' > /boot/loader/loader.conf
          echo 'default @saved' >> /boot/loader/loader.conf
          echo 'console-mode keep' >> /boot/loader/loader.conf
        '';
      };
      efi.canTouchEfiVariables = true;
      timeout = 10;
    };

    kernelParams = [ "cgroup_enable=cpuset" ];
  };

  ##############################################################################
  # General system environment stuff
  time = {
    timeZone = "America/New_York";

    # Need this for dual-booting with Windows
    # https://nixos.wiki/wiki/Dual_Booting_NixOS_and_Windows
    hardwareClockInLocalTime = true;
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  evertras.system.virtualization.enable = true;

  evertras.system.docker.enable = true;

  evertras.dev.tiledb.enable = true;

  ##############################################################################
  # Desktop stuff
  # (keep minimal, use home-manager for most things)
  evertras.desktop.enable = true;

  # We need this for nerdfont and prompts to work for some reason?
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

  networking = {
    hostName = "delltop";
    wireless = {
      # Enables wireless support via wpa_supplicant.
      enable = true;
      userControlled = {
        enable = true;
        group = "wheel";
      };
      networks = {
        # https://nixos.wiki/wiki/Wpa_supplicant
        # Encrypted, and if you crack it then I guess you can
        # drive by my house somewhere and watch Netflix?
        Lowriders = {
          pskRaw =
            "e68178a8d25b7e61d309900870f543b71941288aa187c6245fb10ca31922bc9c";
          priority = 20;
        };

        SpectrumSetup-D3 = {
          pskRaw =
            "e23b2a89c3883c9b78fb3c3689deebf11739b590c8e8b56eb624a89b58188701";
          priority = 20;
        };

        OhBeaufy = {
          pskRaw =
            "d406744fa2fef95124c172c7222689b0a9c018b0dffa6fe2ab48a4961fa0be95";
          priority = 20;
          # Need to do this explicitly for reasons...
          authProtocols = [ "WPA-PSK" ];
        };
      };
    };
  };

  networking.nameservers = [ "8.8.8.8" "10.20.0.2" ];

  ##############################################################################
  # Nvidia stuff
  # https://nixos.wiki/wiki/Nvidia
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    # Experimental stuff, turn off
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    open = true;

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

  environment.variables = {
    # If weird things start happening with the mouse cursor, like flickering etc.,
    # then re-enable this
    #WLR_NO_HARDWARE_CURSORS = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  ##############################################################################
  # Other system-wide packages/programs
  # Keep this minimal, use home-manager for most things

  environment.systemPackages = with pkgs; [
    home-manager

    # Shows power usage, can only be run as root
    powertop

    # Some handy things used while root, try to keep this minimal
    file
    traceroute

    # Useful for finding graphics card info
    # sudo lshw -c display
    lshw

    # PCI bus info (lspci, etc)
    pciutils

    # lsusb
    usbutils
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

