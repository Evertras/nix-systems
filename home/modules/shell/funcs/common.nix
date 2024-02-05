{ config, pkgs, ... }: {
  evertras.home.shell.funcs = {
    # Outside of code because I want to use this with ASDF on a non-NixOS system
    # without installing Go, but it does feel odd
    go-watch-test = {
      runtimeInputs = with pkgs; [ entr fzf ripgrep ];
      body = ''
        #!/usr/bin/env bash

        watchdir=$(rg --files -g '*.go' | xargs dirname | sort -u | fzf --scheme=path -i --tiebreak=end)

        if [ -z "$watchdir" ]; then
          echo "No directory selected"
          exit 1
        fi

        while sleep 1; do find "$watchdir" -iname '*.go' | entr -c -d go test -race "$watchdir"; done
      '';
    };

    replace-all.body = ''
      if [ $# -ne 4 ]; then
        echo "USAGE: change-all <dir> <file-filter> <old-regex> <replacement>"
        echo ""
        echo "       Changes all matches of <old-regex> to <new> in the"
        echo "       <dir> directory and all subdirectories for all files"
        echo "       that match the file-type filter.  Uses sed."
        echo ""
        echo "   ex: change-all '*.go' 'mypkg\.Thing' 'mypkg.BetterName'"
        exit 1
      fi

      dir=$1
      filefilter=$2
      oldregex=$3
      replacement=$4

      echo "Looking in all files with filter '$filefilter'"

      # Show all matches for thorough check with fzf for scrolling
      matches=$(find "$dir" -type f -name "$filefilter" -exec grep -nE "$oldregex" {} +)
      echo "$matches" | fzf --no-sort

      # Show affected files with counts for quick final check when deciding
      find "$dir" -type f -name "$filefilter" -exec grep -cE "$oldregex" {} + | awk -F: '$2 != 0 { print $2 " " $1 }' | col | sort -n

      echo "Replacing any regex pattern match of '$oldregex' with '$replacement' in $dir"
      read -p "Found $(wc -l <<< "$matches") matches.  Continue? [y/n] " -n 1 -r
      echo ""

      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Don't do it"
        exit 1
      fi

      find "$dir" -type f -name "$filefilter" -exec sed -i "s/$oldregex/$replacement/g" {} \;
    '';
  };
}
