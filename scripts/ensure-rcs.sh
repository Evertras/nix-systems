#!/usr/bin/env bash

# TODO: Swap this out for full home-manager

# This is a bit hardcoded at the moment,
# but works enough for now.  I don't want
# to use home-manager because I like my
# rc setup and I use it in various environments.

if [ -d /home/evertras/dev/github/evertras/myrcs ]; then
  # Do nothing
  exit 0
fi

mkdir -p /home/evertras/dev/github/evertras
git clone https://github.com/Evertras/MyRCs /home/evertras/dev/github/evertras/myrcs
/home/evertras/dev/github/evertras/myrcs/scripts/install.sh
