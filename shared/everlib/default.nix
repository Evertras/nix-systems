{ lib }:
with lib;
let concatPaths = base: subdir: base + ("/" + subdir);
in {
  allSubdirs = path:
    let
      fileset = builtins.readDir path;
      dirset = filterAttrs (_: s: s == "directory") fileset;
      dirs = map (concatPaths path) (builtins.attrNames dirset);
    in dirs;
}
