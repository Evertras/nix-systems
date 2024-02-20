{
  # Note to self: nix repl -> builtins.currentSystem
  system = "aarch64-darwin";
  module = ./home.nix;
}
