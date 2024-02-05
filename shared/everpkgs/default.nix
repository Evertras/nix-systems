{ }:
# This file should contain random flake-based packages to install
# to avoid cluttering the main flake file.
let inputs = { cynomys.url = "github:Evertras/cynomys"; };
in { inherit inputs; }
