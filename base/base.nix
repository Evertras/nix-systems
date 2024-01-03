# The non-negotiables that every system should have
{ config, lib, pkgs, ... }:
{
  # Never touch this, we need this for the whole setup to work
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
