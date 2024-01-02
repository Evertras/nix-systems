#!/usr/bin/env bash

if [ ! -f /etc/nixos/passwords/evertras ]; then
  sudo mkdir -p /etc/nixos/passwords/
  while [ "${password}" != "${password_confirm}" ] || [ -z "${password}" ]; do
    read -s -p "Set evertras password: " password
    echo ""
    read -s -p "Confirm evertras password: " password_confirm
    echo ""
  done
  echo "Writing password hash to /etc/nixos/passwords/evertras"
  mkpasswd "${password}" | sudo tee /etc/nixos/passwords/evertras
  sudo chmod 0600 /etc/nixos/passwords/evertras
fi
