.PHONY: help check install clean test all

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)Development Environment Checker$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Quick start:$(NC)"
	@echo "  1. Run '$(YELLOW)make check$(NC)' to see what's installed"
	@echo "  2. Run '$(YELLOW)make install$(NC)' to install missing packages"
	@echo "  3. Run '$(YELLOW)make test$(NC)' to verify everything works"
	@echo ""

check: ## Check current environment setup
	@echo "$(BLUE)Checking development environment...$(NC)"
	@chmod +x check_dev_environment.py
	@./check_dev_environment.py

install: ## Install missing packages
	@echo "$(BLUE)Installing missing packages...$(NC)"
	@chmod +x install_missing.sh
	@./install_missing.sh

test: check ## Run checks (alias for 'check')

all: install check ## Install everything and run checks
	@echo "$(GREEN)Setup complete!$(NC)"

clean: ## Clean up temporary files
	@echo "$(BLUE)Cleaning up...$(NC)"
	@rm -rf __pycache__
	@rm -f *.pyc
	@echo "$(GREEN)Done!$(NC)"

install-homebrew: ## Install Homebrew (if not present)
	@if ! command -v brew &> /dev/null; then \
		echo "$(YELLOW)Installing Homebrew...$(NC)"; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	else \
		echo "$(GREEN)✓ Homebrew already installed$(NC)"; \
	fi

install-sheldon: ## Install Sheldon plugin manager
	@if [ ! -f "$$HOME/.local/bin/sheldon" ]; then \
		echo "$(YELLOW)Installing Sheldon...$(NC)"; \
		mkdir -p "$$HOME/.local/bin"; \
		curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | \
			bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin --tag 0.6.6; \
		echo "$(GREEN)✓ Sheldon installed$(NC)"; \
	else \
		echo "$(GREEN)✓ Sheldon already installed$(NC)"; \
	fi

install-chezmoi: ## Install Chezmoi dotfile manager
	@if ! command -v chezmoi &> /dev/null; then \
		echo "$(YELLOW)Installing Chezmoi...$(NC)"; \
		sh -c "$$(curl -fsLS chezmoi.io/get)"; \
		echo "$(GREEN)✓ Chezmoi installed$(NC)"; \
	else \
		echo "$(GREEN)✓ Chezmoi already installed$(NC)"; \
	fi

install-asdf: ## Install ASDF version manager
	@if ! command -v asdf &> /dev/null; then \
		echo "$(YELLOW)Installing ASDF...$(NC)"; \
		brew install asdf; \
		echo "$(GREEN)✓ ASDF installed$(NC)"; \
		echo "$(YELLOW)⚠ Add this to your ~/.zshrc:$(NC)"; \
		echo "  . $$(brew --prefix asdf)/libexec/asdf.sh"; \
	else \
		echo "$(GREEN)✓ ASDF already installed$(NC)"; \
	fi

setup-all: install-homebrew install-sheldon install-chezmoi install-asdf install ## Full setup from scratch
	@echo ""
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)Full setup complete!$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  1. Restart your shell: exec zsh"
	@echo "  2. Initialize chezmoi: chezmoi init --apply https://github.com/bossjones/zsh-dotfiles.git"
	@echo "  3. Run 'make check' to verify"
	@echo ""

version: ## Show versions of key tools
	@echo "$(BLUE)Tool Versions:$(NC)"
	@echo ""
	@command -v brew >/dev/null 2>&1 && echo "Homebrew:  $$(brew --version | head -n1)" || echo "Homebrew:  $(RED)Not installed$(NC)"
	@command -v python3 >/dev/null 2>&1 && echo "Python:    $$(python3 --version)" || echo "Python:    $(RED)Not installed$(NC)"
	@[ -f "$$HOME/.local/bin/sheldon" ] && echo "Sheldon:   $$("$$HOME/.local/bin/sheldon" --version)" || echo "Sheldon:   $(RED)Not installed$(NC)"
	@command -v chezmoi >/dev/null 2>&1 && echo "Chezmoi:   $$(chezmoi --version | head -n1)" || echo "Chezmoi:   $(RED)Not installed$(NC)"
	@command -v asdf >/dev/null 2>&1 && echo "ASDF:      $$(asdf version)" || echo "ASDF:      $(RED)Not installed$(NC)"
	@echo ""

# Hidden targets (not shown in help)
.PHONY: _check_python
_check_python:
	@command -v python3 >/dev/null 2>&1 || (echo "$(RED)Error: Python 3 is required$(NC)" && exit 1)
