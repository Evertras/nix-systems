{ pkgs, ... }:
let
  dockerfileSrc = pkgs.writeText "claude-sandbox-dockerfile" ''
    FROM node:lts-slim

    RUN apt-get update && apt-get install -y \
        git \
        ca-certificates \
        curl \
        xz-utils \
        && rm -rf /var/lib/apt/lists/*

    # Install Nix via Determinate Systems installer — handles root + no-init containers
    RUN curl --proto =https --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
        | sh -s -- install linux --init none --no-confirm

    # Disable build sandbox (requires kernel namespaces unavailable in Docker)
    RUN echo "sandbox = false" >> /etc/nix/nix.conf

    ENV PATH="/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/root/.local/bin:${
      "$"
    }{PATH}"

    RUN curl -fsSL https://claude.ai/install.sh | bash \
        && cp /root/.local/bin/claude /usr/local/bin/claude \
        && chmod 755 /root

    RUN tee /entrypoint.sh <<SCRIPT && chmod +x /entrypoint.sh
    #!/bin/sh
    if [ -f flake.nix ] && grep -q 'devShells' flake.nix; then
      exec nix develop --command claude "\$@"
    fi
    if [ -f shell.nix ]; then
      exec nix-shell --run "claude \$*"
    fi
    exec claude "\$@"
    SCRIPT

    WORKDIR /sandbox

    ENTRYPOINT ["/entrypoint.sh"]
  '';
in {
  evertras.home.shell.funcs = {
    claude-sandbox = {
      body = ''
        image_name="evertras-claude-sandbox"
        build_args=()

        if [ "''${1:-}" = "--rebuild" ]; then
          shift
          docker rmi "''${image_name}" 2>/dev/null || true
          build_args+=(--no-cache)
        fi

        if [ "''${#build_args[@]}" -gt 0 ] || ! docker image inspect "''${image_name}" &>/dev/null; then
          echo "Building Claude sandbox image..."
          docker build "''${build_args[@]}" -t "''${image_name}" - < ${dockerfileSrc}
        fi

        claude_json="''${HOME}/.claude.json"
        claude_json_mount=()
        if [ -f "''${claude_json}" ]; then
          claude_json_mount=(-v "''${claude_json}:/root/.claude.json")
        fi

        sandbox_dir="/sandbox$(pwd)"
        dir_hash=$(pwd | sha256sum | cut -c1-12)
        nix_volume="''${image_name}-nix-''${dir_hash}"

        # Use the host user ID so that files created/modified inside the
        # container are owned by the correct user on the host filesystem.
        docker run --rm -it \
          -e TERM="''${TERM}" \
          -e HOME=/root \
          --user "$(id -u):$(id -g)" \
          --workdir "''${sandbox_dir}" \
          -v "$(pwd):''${sandbox_dir}" \
          -v "''${HOME}/.claude:/root/.claude" \
          -v "''${nix_volume}:/nix" \
          "''${claude_json_mount[@]}" \
          "''${image_name}" "''${@}"
      '';
    };
  };
}
