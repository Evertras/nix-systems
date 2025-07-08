.PHONY: home
home: .git/hooks/pre-commit
	nix run home-manager/release-25.05 -- switch --flake .#${EVERTRAS_USER_PROFILE} --show-trace

.PHONY: home-news
home-news: .git/hooks/pre-commit
	home-manager news --flake .#${EVERTRAS_USER_PROFILE}

.PHONY: system
system: .git/hooks/pre-commit
	@./scripts/ensure-passwords.sh
	sudo nixos-rebuild switch --flake .

# Starts a local VM with the vm-playground configuration.
# Log in with evertras/evertras.
.PHONY: playground
playground: .git/hooks/pre-commit
	rm -f nixbox-playground.qcow2 && nix run '.#nixosConfigurations.vm-playground.config.system.build.vm'

.PHONY: clean-home
clean-home: .git/hooks/pre-commit
	nix-collect-garbage -d

.PHONY: clean-system
clean-system: .git/hooks/pre-commit
	sudo nix-collect-garbage -d
	sudo nixos-rebuild boot --flake .

.PHONY: fmt
fmt: .git/hooks/pre-commit
	@nixfmt .

.PHONY: lint
lint: .git/hooks/pre-commit
	@nix-shell -p shellcheck --run "shellcheck ./scripts/*"

.PHONY: update-fonts
update-fonts: .git/hooks/pre-commit
	nix flake lock --update-input ever-fonts

# Should not need to do this often, but sometimes need to unstick...
.PHONY: update-flake
update-flake: .git/hooks/pre-commit
	nix flake update

.git/hooks/pre-commit: .evertras/pre-commit.sh
	cp .evertras/pre-commit.sh .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit
