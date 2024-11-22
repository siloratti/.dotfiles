# Variables
INSTALL_SCRIPT = install_packages.sh
SYMLINK_SCRIPT = setup_config_links.sh
SHELL := /bin/bash

# Colors for prettier output
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RESET := \033[0m

# Default target
.PHONY: all
all: install setup-dotfiles
	@echo "$(GREEN)All tasks completed!$(RESET)"
	@echo "$(YELLOW)Please reboot your system to ensure all changes take effect.$(RESET)"

# Install packages
.PHONY: install
install: make-executable-install
	@echo "$(CYAN)Installing packages...$(RESET)"
	@./$(INSTALL_SCRIPT)

# Setup dotfiles
.PHONY: setup-dotfiles
setup-dotfiles: make-executable-symlink
	@echo "$(CYAN)Setting up dotfiles...$(RESET)"
	@./$(SYMLINK_SCRIPT)

# Make scripts executable
.PHONY: make-executable-install
make-executable-install:
	@echo "$(CYAN)Making install script executable...$(RESET)"
	@chmod +x $(INSTALL_SCRIPT)

.PHONY: make-executable-symlink
make-executable-symlink:
	@echo "$(CYAN)Making symlink script executable...$(RESET)"
	@chmod +x $(SYMLINK_SCRIPT)

# Individual targets for running scripts separately
.PHONY: packages-only
packages-only: make-executable-install
	@echo "$(CYAN)Running package installation only...$(RESET)"
	@./$(INSTALL_SCRIPT)

.PHONY: dotfiles-only
dotfiles-only: make-executable-symlink
	@echo "$(CYAN)Running dotfiles setup only...$(RESET)"
	@./$(SYMLINK_SCRIPT)

# Clean target
.PHONY: clean
clean:
	@echo "$(CYAN)Cleaning up...$(RESET)"
	@echo "Cleaning package cache..."
	@sudo pacman -Scc --noconfirm
	@command -v yay >/dev/null 2>&1 && yay -Scc --noconfirm || echo "yay not installed, skipping AUR cache cleanup"
	@echo "Removing backup directories..."
	@rm -rf ~/.config_backup/*

# Help target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  $(GREEN)make$(RESET)              - Run complete setup (packages and dotfiles)"
	@echo "  $(GREEN)make packages-only$(RESET) - Install packages only"
	@echo "  $(GREEN)make dotfiles-only$(RESET) - Setup dotfiles only"
	@echo "  $(GREEN)make clean$(RESET)         - Clean package cache and backups"
	@echo "  $(GREEN)make help$(RESET)          - Show this help message"
	@echo ""
	@echo "Order of operations for 'make':"
	@echo "1. Install packages ($(INSTALL_SCRIPT))"
	@echo "2. Setup dotfiles ($(SYMLINK_SCRIPT))"
