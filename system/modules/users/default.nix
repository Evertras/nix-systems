# For now just evertras everywhere as the base
# Be careful when editing this to not lock yourself out...
{ ... }: {
  config = {
    users = {
      mutableUsers = false;

      users.evertras = {
        isNormalUser = true;
        extraGroups =
          [ "audio" "docker" "autologin" "wheel" "libvirtd" "input" ];
        hashedPasswordFile = "/etc/nixos/passwords/evertras";
      };
    };

    security.sudo.wheelNeedsPassword = false;
  };
}
