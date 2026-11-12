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

    # Fast-forward the default branch of every repo under a root directory
    # (default ~/dev/github, laid out as <org>/<repo>).  The default branch is
    # asked of the remote each time rather than guessed, so main/master/other
    # all work and a renamed default is picked up.  Only ever fast-forwards:
    # diverged branches and conflicting local changes are reported, not merged.
    git-update-main.body = ''
      root="''${1:-''${HOME}/dev/github}"
      jobs=8

      update_repo() {
        local repo="''${1}" default current

        if ! git -C "''${repo}" remote get-url origin &>/dev/null; then
          echo "skip: no origin remote"
          return 0
        fi

        # Ask the remote which branch HEAD points at; fall back to the local
        # origin/HEAD if the remote can't be reached for the symref.
        default="$(git -C "''${repo}" ls-remote --symref origin HEAD 2>/dev/null \
          | awk '/^ref:/ { sub("refs/heads/", "", $2); print $2; exit }' || true)"
        if [ -z "''${default}" ]; then
          default="$(git -C "''${repo}" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
          default="''${default#origin/}"
        fi
        if [ -z "''${default}" ]; then
          echo "FAIL: could not determine default branch"
          return 1
        fi

        current="$(git -C "''${repo}" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"

        if [ "''${current}" = "''${default}" ]; then
          # Checked out: fetch, then fast-forward the working tree.
          if ! git -C "''${repo}" fetch --quiet origin "''${default}" \
            || ! git -C "''${repo}" merge --ff-only --quiet "origin/''${default}"; then
            echo "FAIL: could not fast-forward ''${default} (checked out)"
            return 1
          fi
        elif git -C "''${repo}" show-ref --verify --quiet "refs/heads/''${default}"; then
          # Not checked out: update the local branch ref directly.  The fetch
          # refuses anything that isn't a fast-forward.
          git -C "''${repo}" fetch --quiet origin "''${default}:''${default}" \
            || { echo "FAIL: could not fast-forward ''${default}"; return 1; }
        else
          # No local branch of that name; just refresh origin/<default>.
          git -C "''${repo}" fetch --quiet origin "''${default}" \
            || { echo "FAIL: could not fetch ''${default}"; return 1; }
        fi

        echo "ok: ''${default} @ $(git -C "''${repo}" rev-parse --short "origin/''${default}")"
      }

      if [ ! -d "''${root}" ]; then
        echo "git-update-main: no such directory: ''${root}" >&2
        exit 1
      fi

      # Repos sit at <root>/<org>/<repo>, or directly at <root>/<repo> when
      # given an org dir.  A .git file (worktree/submodule) counts too.
      mapfile -t repos < <(find "''${root}" -mindepth 2 -maxdepth 3 -name .git -printf '%h\n' | sort)
      if [ "''${#repos[@]}" -eq 0 ]; then
        echo "git-update-main: no repositories found under ''${root}" >&2
        exit 1
      fi

      # Never stop to ask for credentials: in parallel the prompts would
      # interleave, and one hung repo would stall the run.
      export GIT_TERMINAL_PROMPT=0

      # Run in parallel, each repo's output buffered to its own file, then
      # print in order so the results read cleanly.
      out_dir="$(mktemp -d)"
      trap 'rm -rf "''${out_dir}"' EXIT

      for i in "''${!repos[@]}"; do
        while [ "$(jobs -rp | wc -l)" -ge "''${jobs}" ]; do
          wait -n || true
        done
        (
          if update_repo "''${repos[$i]}" > "''${out_dir}/''${i}" 2>&1; then
            touch "''${out_dir}/''${i}.ok"
          fi
        ) &
      done
      wait

      failed=0
      for i in "''${!repos[@]}"; do
        printf '%-60s %s\n' "''${repos[$i]#"''${root}/"}" "$(tr '\n' ' ' < "''${out_dir}/''${i}")"
        if [ ! -e "''${out_dir}/''${i}.ok" ]; then
          failed=$((failed + 1))
        fi
      done

      if [ "''${failed}" -gt 0 ]; then
        echo "''${failed} of ''${#repos[@]} repositories failed" >&2
        exit 1
      fi
    '';

    gadd.body = ''
      cd "$(git rev-parse --show-toplevel)"
      tmpfile=$(mktemp)
      git status --porcelain | awk '/^.M/ || /^\?\?/ {printf "%s\0", $2}' | fzf --scheme=path -i --tiebreak=end --preview 'git diff --color {+1}' --read0 --print0 > "$tmpfile"
      if [ -s "$tmpfile" ]; then
        xargs -0 -r git add < "$tmpfile"
        xargs -0 -r -I{} echo "Added: {}" < "$tmpfile"
      fi
      rm -f "$tmpfile"
    '';
  };
}
