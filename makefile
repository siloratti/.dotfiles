# --- Variables ---
# Define script names for easy modification
INSTALL_SCRIPT = install_packages.sh
SYMLINK_SCRIPT = setup_config_links.sh
# Force bash as shell (important for script compatibility)
SHELL := /bin/bash

# ANSI color codes for prettier output
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RESET := \033[0m

# --- Primary Targets ---
# .PHONY tells Make these aren't files but commands
.PHONY: all
# Default target (runs when you type just 'make')
all: install setup-dotfiles
	@echo "$(GREEN)All tasks completed!$(RESET)"
	@echo "$(YELLOW)Please reboot your system to ensure all changes take effect.$(RESET)"
# The @ symbol prevents the command from being printed before execution
# Dependencies: 'install' and 'setup-dotfiles' must complete before these echo commands

# --- Installation Targets ---
.PHONY: install
install: make-executable-install
	@echo "$(CYAN)Installing packages...$(RESET)"
	@./$(INSTALL_SCRIPT)
# Depends on make-executable-install (ensures script is executable)

.PHONY: setup-dotfiles
setup-dotfiles: make-executable-symlink
	@echo "$(CYAN)Setting up dotfiles...$(RESET)"
	@./$(SYMLINK_SCRIPT)
# Depends on make-executable-symlink

# --- Script Preparation Targets ---
.PHONY: make-executable-install
make-executable-install:
	@echo "$(CYAN)Making install script executable...$(RESET)"
	@chmod +x $(INSTALL_SCRIPT)
# Makes the installation script executable

.PHONY: make-executable-symlink
make-executable-symlink:
	@echo "$(CYAN)Making symlink script executable...$(RESET)"
	@chmod +x $(SYMLINK_SCRIPT)
# Makes the symlink script executable

# --- Individual Operation Targets ---
.PHONY: packages-only
packages-only: make-executable-install
	@echo "$(CYAN)Running package installation only...$(RESET)"
	@./$(INSTALL_SCRIPT)
# Allows running just the package installation

.PHONY: dotfiles-only
dotfiles-only: make-executable-symlink
	@echo "$(CYAN)Running dotfiles setup only...$(RESET)"
	@./$(SYMLINK_SCRIPT)
# Allows running just the dotfiles setup

# --- Cleanup Target ---
.PHONY: clean
clean:
	@echo "$(CYAN)Cleaning up...$(RESET)"
	@echo "Cleaning package cache..."
	# Clean pacman cache (--noconfirm prevents prompts)
	@sudo pacman -Scc --noconfirm
	# Clean yay cache if yay exists
	@command -v yay >/dev/null 2>&1 && yay -Scc --noconfirm || echo "yay not installed, skipping AUR cache cleanup"
	@echo "Removing backup directories..."
	@rm -rf ~/.config_backup/*
