.PHONY: rebuild
rebuild: .git/hooks/pre-commit
	@./scripts/ensure-passwords.sh
	@./scripts/ensure-channel.sh
	sudo nixos-rebuild switch --flake .
	home-manager switch --flake .
	@sudo -u evertras ./scripts/ensure-rcs.sh

.PHONY: home
home: .git/hooks/pre-commit
	@./scripts/ensure-channel.sh
	home-manager switch --flake .

.PHONY: fmt
fmt:
	@nixfmt .

.git/hooks/pre-commit: .evertras/pre-commit.sh
	cp .evertras/pre-commit.sh .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit
