.DEFAULT_GOAL := help

DC := docker compose

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the workspace image
	$(DC) build

dev: ## Start the workspace container
	$(DC) up -d

shell: ## Open a shell in the workspace container
	$(DC) exec workspace bash

claude: ## Run Claude Code in the workspace container
	$(DC) exec workspace claude

codex: ## Run Codex in the workspace container
	$(DC) exec workspace codex

ab-start: ## Start agent-browser on the host
	agent-browser stream enable --port 9223

clean: ## Stop containers and remove volumes
	$(DC) down -v

.PHONY: help build dev shell claude codex ab-start clean
