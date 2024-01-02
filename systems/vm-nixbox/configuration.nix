{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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

  # Desktop environment
  # https://nixos.wiki/wiki/I3
  services.xserver = {
    enable = true;
    layout = "jp";

    displayManager = {
      defaultSession = "none+i3";

      autoLogin.user = "evertras";

      # Sleep seems to be required for avoiding some init race,
      # not great but works for now
      sessionCommands = ''
        xrandr --output Virtual1 --mode 2560x1440
        picom -f &
        (sleep 1s && setxkbmap -layout jp && styli.sh -s mountain) &
      '';

      # Explicitly enable lightDM in case we log back out,
      # just to remind ourselves which thing we're using...
      lightdm = {
        enable = true;
      };
    };

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        i3status
        i3lock
        # TODO: look at i3blocks?
      ];
    };

    # Disable capslock, trying to remap it to ctrl
    # seems to do some weird things
    xkb.options = "caps:none";
  };

  networking.nameservers = [ "8.8.8.8" ]; 
  services.resolved = {
    enable = true;
    fallbackDns = [ "8.8.8.8" ];
  };

  users.mutableUsers = false;
  users.users.evertras = {
    isNormalUser = true;
    extraGroups = [
      "autologin"
      "wheel"
    ];
    hashedPasswordFile = "/etc/nixos/passwords/evertras";
  };

  security.sudo.wheelNeedsPassword = false;

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
    picom-next
    stylish

    # Coding
    cargo
    gcc
    gnumake
    go
    nodejs_21
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

