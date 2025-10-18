{ pkgs }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    (python3.withPackages (ps: with ps; [ numpy ]))
    python3Packages.venvShellHook
    zstd
    pkg-config
  ];

  venvDir = "/home/evertras/.evertras/venv/tiledb";
}

