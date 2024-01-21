.PHONY: home
home: .git/hooks/pre-commit
	@./scripts/ensure-channel.sh
	home-manager switch --flake .#${EVERTRAS_USER_PROFILE} --show-trace

.PHONY: home-news
home-news: .git/hooks/pre-commit
	home-manager news --flake .#${EVERTRAS_USER_PROFILE}

.PHONY: system
system: .git/hooks/pre-commit
	@./scripts/ensure-passwords.sh
	@./scripts/ensure-channel.sh
	sudo nixos-rebuild switch --flake .

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

.git/hooks/pre-commit: .evertras/pre-commit.sh
	cp .evertras/pre-commit.sh .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit
