{ pkgs, ... }:
let
  dockerfileSrc = pkgs.writeText "claude-sandbox-dockerfile" ''
    FROM node:lts-slim

    RUN apt-get update && apt-get install -y \
        git \
        ca-certificates \
        curl \
        && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
        && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
        && apt-get update && apt-get install -y gh \
        && rm -rf /var/lib/apt/lists/*

    ENV PATH="/root/.local/bin:${"$"}{PATH}"

    RUN curl -fsSL https://claude.ai/install.sh | bash

    RUN git config --global --add safe.directory '*'

    RUN mkdir -p /home/user && chmod 777 /home/user

    WORKDIR /sandbox

    ENTRYPOINT ["claude"]
  '';
in
{
  evertras.home.shell.funcs = {
    claude-sandbox = {
      body = ''
        image_name="evertras-claude-sandbox"

        need_build=false
        dirs=()
        passthrough_args=()

        while [[ $# -gt 0 ]]; do
          case "''${1}" in
            --rebuild)
              docker rmi "''${image_name}" 2>/dev/null || true
              need_build=true
              shift
              ;;
            -d)
              dirs+=("$(realpath "''${2}")")
              shift 2
              ;;
            *)
              passthrough_args+=("''${1}")
              shift
              ;;
          esac
        done

        if ! docker image inspect "''${image_name}" &>/dev/null; then
          need_build=true
        fi

        if "''${need_build}"; then
          echo "Building Claude sandbox image..."
          docker build -t "''${image_name}" - < ${dockerfileSrc}
        fi

        claude_json="''${HOME}/.claude.json"
        claude_json_mount=()
        if [ -f "''${claude_json}" ]; then
          claude_json_mount=(-v "''${claude_json}:/home/user/.claude.json")
        fi

        # If no -d flags given, default to current directory
        if [ "''${#dirs[@]}" -eq 0 ]; then
          dirs=("$(pwd)")
        fi

        volume_mounts=()
        for dir in "''${dirs[@]}"; do
          volume_mounts+=(-v "''${dir}:/sandbox''${dir}")
        done

        sandbox_dir="/sandbox''${dirs[0]}"

        # --user is required so that files created/modified in the volume mount
        # are owned by the calling user rather than root.
        # HOME must point to a world-writable path since the container user is
        # a dynamic UID with no real home directory.
        docker run --rm -it \
          --user "$(id -u):$(id -g)" \
          -e HOME=/home/user \
          -e TERM="''${TERM}" \
          --workdir "''${sandbox_dir}" \
          "''${volume_mounts[@]}" \
          -v "''${HOME}/.claude:/home/user/.claude" \
          "''${claude_json_mount[@]}" \
          "''${image_name}" "''${passthrough_args[@]}"
      '';
    };
  };
}
