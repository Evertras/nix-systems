# For now just evertras everywhere as the base
# Be careful when editing this to not lock yourself out...
{ config, lib, pkgs, ... }:
{
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
}
