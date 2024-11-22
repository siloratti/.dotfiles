# Variables
SCRIPT_NAME = setup_config_links.sh
SHELL := /bin/bash

# Default target
.PHONY: all
all: make-executable run

# Make script executable
.PHONY: make-executable
make-executable:
	@echo "Making script executable..."
	@chmod +x $(SCRIPT_NAME)

# Run the script
.PHONY: run
run:
	@echo "Running configuration script..."
	@./$(SCRIPT_NAME)

# Clean target (optional)
.PHONY: clean
clean:
	@echo "Cleaning up backups..."
	@rm -rf ~/.config_backup/*

# Help target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make         - Make script executable and run it"
	@echo "  make clean   - Remove backup directories"
	@echo "  make help    - Show this help message"
