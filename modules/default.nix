{ config, lib, pkgs, ... }:

{
  # All of these should be safe to import and enabled
  # through configuration
  imports = [ ./base ./desktops/i3-standard ./users ];
}
