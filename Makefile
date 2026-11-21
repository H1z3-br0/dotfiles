.PHONY: install test lint

install:
	./install.sh

test:
	@bash -n install.sh
	@bash -n bin/ad
	@bash -n shell/common.sh
	@bash -n .bashrc
	@bash -n .bash_profile
	@if command -v zsh >/dev/null 2>&1; then \
		zsh -n .zshrc .zshenv .zprofile; \
	else \
		echo "zsh not installed, skipping zsh syntax check"; \
	fi
	@echo "syntax OK"

lint:
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck install.sh bin/ad shell/common.sh; \
	else \
		echo "shellcheck not installed"; \
	fi
