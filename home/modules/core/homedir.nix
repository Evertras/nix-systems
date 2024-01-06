{ config }:

let cfg = config.evertras.home.core;
in {
  homeDir = if cfg.homeDirectory == null then
    "/home/${cfg.username}"
  else
    cfg.homeDirectory;
}
