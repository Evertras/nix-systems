{ config, lib, pkgs, ... }:

{
  # All of these should be safe to import and enabled
  # through configuration
  imports = [
    ./base/core.nix
    ./desktops/i3-standard/i3.nix
    ./users/users.nix
  ];
}
