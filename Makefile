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

chrome: ## Start Chrome with remote debugging for agent-browser
	/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
		--remote-debugging-port=9222 \
		--remote-debugging-address=0.0.0.0 \
		--user-data-dir=$(HOME)/.chrome-agent

ab-connect: ## Connect agent-browser to host Chrome (run inside container)
	@WS=$$(curl -s -H "Host: localhost" $$CHROME_CDP_URL/json/version | jq -r .webSocketDebuggerUrl \
		| sed "s|ws://localhost|ws://$${CHROME_CDP_URL#http://}|") && \
	agent-browser connect "$$WS"

clean: ## Stop containers and remove volumes
	$(DC) down -v

.PHONY: help build dev shell claude codex chrome ab-connect clean
