{ config, lib, pkgs, ... }:

let
  kbLayout = "jp";
in {
  imports = [
    ../../base/base.nix
    ../../desktops/i3-standard/i3.nix
    ../../users/users.nix

    ./hardware-configuration.nix
  ];

  evertras.desktop.i3 = {
    inherit kbLayout;
    enable = true;
    extraSessionCommands = ''
      xrandr --output Virtual1 --mode 2560x1440
      (sleep 1s && setxkbmap -layout ${kbLayout} && styli.sh -s mountain) &
    '';
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 2;

  boot.initrd.checkJournalingFS = false;

  networking.hostName = "nixbox";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Tokyo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    keyMap = "jp106";
  };

  networking.nameservers = [ "8.8.8.8" ]; 
  services.resolved = {
    enable = true;
    fallbackDns = [ "8.8.8.8" ];
  };

  services.xserver.displayManager.autoLogin.user = "evertras";

  # System-wide packages
  environment.systemPackages = with pkgs; [
    # System/terminal
    dig
    fzf
    git
    neovim
    pinentry
    ripgrep
    starship
    silver-searcher
    tmux
    tmuxinator

    # Desktop
    feh
    imagemagick
    kitty
    librewolf
    stylish

    # Coding
    cargo
    gcc
    gnumake
    go
    nodejs_21
    python3
    rustc
  ];

  fonts.packages = with pkgs; [
    nerdfonts
  ];

  environment.variables = {
    EDITOR = "nvim";
  };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "curses";
    enableSSHSupport = true;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

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

