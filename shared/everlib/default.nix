{ lib }:
with lib; {
  allSubdirs = path:
    let
      fileset = builtins.readDir path;
      dirset = filterAttrs (_: s: s == "directory") fileset;
      dirs = map (p: path + ("/" + p)) (builtins.attrNames dirset);
    in dirs;
}
