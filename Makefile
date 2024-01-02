.PHONY: rebuild
rebuild:
	@./scripts/ensure-passwords.sh
	sudo nixos-rebuild switch --flake .

