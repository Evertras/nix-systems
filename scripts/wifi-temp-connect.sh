#!/usr/bin/env bash

# TODO: configurable with default
interface=wlo1
config_file=/tmp/evertras-tmp-wifi.conf

set -e

read -r -p "SSID: " ssid
read -r -s -p "Password: " password
echo ""

wpa_passphrase "$ssid" "$password" | grep -v "#psk" > ${config_file}

echo "Starting wpa_supplicant for SSID $ssid"
sudo wpa_supplicant -c /tmp/evertras-tmp-wifi.conf -B -i "${interface}"
