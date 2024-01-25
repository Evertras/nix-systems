{ config, ... }: {
  evertras.home.shell.funcs = {
    # Outside of code because I want to use this with ASDF on a non-NixOS system
    # without installing Go, but it does feel odd
    go-watch-test.body = ''
      #!/usr/bin/env bash

      watchdir=$(find . \( -name ".git" -or -name "vendor" \) -prune -o -type d -exec sh -c 'ls -1 "{}"/*.go 2>/dev/null | wc -l | grep -q "[1-9]" && echo "{}"' \; | fzf --scheme=path -i --tiebreak=end)

      if [ -z "$watchdir" ]; then
        echo "No directory selected"
        exit 0
      fi

      while sleep 1; do ls "$watchdir"/*.go | entr -c -d go test -race "$watchdir"; done
    '';
  };
}
