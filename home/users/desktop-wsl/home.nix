{ ... }:
let
  gpgKey = "8A328FE58AAC42CE";
in
{
  imports = [
    ../../modules
    ../../../shared/themes/select.nix
  ];

  evertras.home.core = {
    username = "evertras";

    # WSL runs on top of Ubuntu, not NixOS
    usingNixOS = false;
  };

  evertras.home.shell.core = { inherit gpgKey; };

  home = {
    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };
}
