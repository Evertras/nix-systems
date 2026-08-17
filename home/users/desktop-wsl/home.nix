{ ... }:

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

  # One-off for this machine: nothing in home/modules/shell starts an
  # ssh-agent or loads a key, so do it here. Consider promoting this into a
  # shared module (e.g. evertras.home.shell.ssh) if other machines end up
  # needing the same thing.
  programs.fish.shellInit = ''
    if not set -q SSH_AUTH_SOCK
      eval (ssh-agent -c) >/dev/null
    end

    if not ssh-add -l >/dev/null 2>&1
      ssh-add ~/.ssh/id_ed25519 2>/dev/null
    end
  '';

  home = {
    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };
}
