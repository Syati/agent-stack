.DEFAULT_GOAL := help

DC := docker compose
-include .env
CHROME_REMOTE_PORT ?= 9222

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the workspace image
	@$(DC) build

dev: ## Start the workspace container
	@$(DC) up -d

shell: ## Open a shell in the workspace container
	@$(DC) exec workspace bash

claude: ## Run Claude Code in the workspace container
	@$(DC) exec workspace claude

codex: ## Run Codex in the workspace container
	@$(DC) exec workspace codex

chrome: ## Start Chrome with remote debugging for agent-browser
	/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
		--remote-debugging-port=$(CHROME_REMOTE_PORT) \
		--remote-debugging-address=0.0.0.0 \
		--user-data-dir=$(HOME)/.chrome-agent

clean: ## Stop containers and remove volumes
	@$(DC) down -v

.PHONY: help build dev shell claude codex chrome clean
