{ pkgs, ... }:
let
  dockerfileSrc = pkgs.writeText "claude-sandbox-dockerfile" ''
    FROM node:lts-slim

    RUN apt-get update && apt-get install -y \
        git \
        ca-certificates \
        curl \
        && rm -rf /var/lib/apt/lists/*

    ENV PATH="/root/.local/bin:${"$"}{PATH}"

    RUN curl -fsSL https://claude.ai/install.sh | bash

    WORKDIR /workspace

    ENTRYPOINT ["claude"]
  '';
in {
  evertras.home.shell.funcs = {
    claude-sandbox = {
      body = ''
        image_name="evertras-claude-sandbox"

        if [ "''${1:-}" = "--rebuild" ]; then
          shift
          docker rmi "''${image_name}" 2>/dev/null || true
        fi

        if ! docker image inspect "''${image_name}" &>/dev/null; then
          echo "Building Claude sandbox image..."
          docker build -t "''${image_name}" - < ${dockerfileSrc}
        fi

        claude_json="''${HOME}/.claude.json"
        claude_json_mount=()
        if [ -f "''${claude_json}" ]; then
          claude_json_mount=(-v "''${claude_json}:/root/.claude.json")
        fi

        docker run --rm -it \
          -e TERM="''${TERM}" \
          -v "$(pwd):/workspace" \
          -v "''${HOME}/.claude:/root/.claude" \
          "''${claude_json_mount[@]}" \
          "''${image_name}" "''${@}"
      '';
    };
  };
}
