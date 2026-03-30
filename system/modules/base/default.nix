# The non-negotiables that every system must have defined
{ pkgs, ... }: {
  # Never touch this, we need this for the whole setup to work
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs;
    [
      # By default iptables uses nftables, but we want to have the CLI command too
      nftables
    ];
}
