{ ... }: {
  evertras.home.shell.funcs = {
    git-merged.body = ''
      main_branch="main"

      if git branch | grep ' master$' &>/dev/null; then
        main_branch="master"
      fi

      branch=$(git rev-parse --abbrev-ref HEAD)

      if [ "''${branch}" == "''${main_branch}" ]; then
        echo "Cannot run this on $main_branch branch!"
        exit 1
      fi

      git checkout "''${main_branch}"
      git pull
      git branch -d "''${branch}"
    '';

    gadd.body = ''
      cd "$(git rev-parse --show-toplevel)"
      to_add=$(git status --porcelain | awk '/^.M/ || /^\?\?/ {printf "%s\0", $2}' | fzf --scheme=path -i --tiebreak=end --preview 'git diff --color {+1}' --read0 --print0)
      if [ -n "$to_add" ]; then
        git add "$to_add"
        echo "Added $to_add"
      fi
    '';
  };
}
