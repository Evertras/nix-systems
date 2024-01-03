# The non-negotiables that every system must have defined
{ ... }: {
  # Never touch this, we need this for the whole setup to work
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
