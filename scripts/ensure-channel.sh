#!/usr/bin/env bash

set -e

if [ -n "EVERTRAS_NO_UPDATE_CHANNEL" ]; then
  exit 0
fi

if sudo nix-channel --list | grep home-manager &>/dev/null; then
  # Don't need to do anything
  exit 0
fi

# Get matching version with NixOS - may not work with unstable
raw=$(sudo nix-channel --list | grep nixos)
url="https://github.com/nix-community/home-manager/archive/release-${raw#*nixos-}.tar.gz" 
sudo nix-channel --add "${url}" home-manager
sudo nix-channel --update
