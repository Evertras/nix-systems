# A VM playground fully managed by NixOS without homemanager,
# intended to learn how NixOS may work as a remote configuration tool.
{ config, lib, pkgs, ... }:

let
  themes = import ../../../shared/themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Green"; };
in {
  imports = [ ../../modules ];

  ##############################################################################
  # Boot stuff

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
  # Networking stuff

  networking = { hostName = "vm-playground"; };

  # TODO: Doing this because local DNS doesn't work, investigate
  networking.nameservers = [ "8.8.8.8" ];
  services.resolved = {
    enable = true;
    fallbackDns = [ "8.8.8.8" ];
  };

  ##############################################################################
  # Other system-wide packages/programs

  environment.systemPackages = with pkgs; [ file ];

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

