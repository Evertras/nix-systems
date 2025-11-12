#!/usr/bin/env bash

# TODO: configurable with default
interface=wlo1

set -e

read -r -p "SSID: " ssid
read -r -s -p "Password: " password
echo ""

echo "Starting wpa_supplicant for SSID $ssid"
sudo wpa_supplicant -B -i "${interface}" <(wpa_passphrase "$ssid" "$password")
