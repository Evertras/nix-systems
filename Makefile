.PHONY: rebuild
rebuild:
	@./scripts/ensure-passwords.sh
	@./scripts/ensure-channel.sh
	sudo nixos-rebuild switch --flake .
	home-manager switch --flake .
	@sudo -u evertras ./scripts/ensure-rcs.sh

.PHONY: home
home:
	home-manager switch --flake .
