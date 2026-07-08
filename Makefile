.PHONY: help build build-no-cache

IMAGE ?= agent-stack:local
DOCKERFILE ?= docker/Dockerfile
BUILD_CONTEXT ?= .

help:
	@echo "Targets:"
	@echo "  make build           Build $(IMAGE) from $(DOCKERFILE)"
	@echo "  make build-no-cache  Build $(IMAGE) without cache"
	@echo ""
	@echo "Variables:"
	@echo "  IMAGE=repo/name:tag"
	@echo "  DOCKERFILE=path/to/Dockerfile"
	@echo "  BUILD_CONTEXT=path/to/context"

build:
	docker build -t "$(IMAGE)" -f "$(DOCKERFILE)" "$(BUILD_CONTEXT)"

build-no-cache:
	docker build --no-cache -t "$(IMAGE)" -f "$(DOCKERFILE)" "$(BUILD_CONTEXT)"
