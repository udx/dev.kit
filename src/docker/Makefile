# Variables
IMAGE_NAME ?= usabilitydynamics/udx-worker
TAG ?= latest
DOCKER_IMAGE := $(IMAGE_NAME):$(TAG)
DEBUG ?= false
MULTIPLATFORM ?= false

# Colors for better visibility
COLOR_RESET=\033[0m
COLOR_BLUE=\033[34m
COLOR_GREEN=\033[32m
COLOR_RED=\033[31m
COLOR_YELLOW=\033[33m

# Symbols
SYM_ARROW=➜
SYM_SUCCESS=✔
SYM_ERROR=✖
SYM_WARNING=⚠

# Default target
.DEFAULT_GOAL := help

.PHONY: run run-it clean build exec log test dev-pipeline

# Use BuildKit for better output
export DOCKER_BUILDKIT=1


.SILENT: build run run-it clean exec log test dev-pipeline

# Common shell function for error handling and output
define exec_with_status
@bash -c 'set -eo pipefail; \
	printf "$(COLOR_BLUE)$(SYM_ARROW) %s$(COLOR_RESET)\n" "$(1)"; \
	{ $(2); } && \
		printf "$(COLOR_GREEN)$(SYM_SUCCESS) %s$(COLOR_RESET)\n" "$(3)" || \
		{ printf "$(COLOR_RED)$(SYM_ERROR) %s$(COLOR_RESET)\n" "$(4)"; exit 1; }'
endef

build:
	@bash -c 'set -eo pipefail; \
		filter="(error|Error|ERROR|failed|Failed|FAILED|\\[.*[0-9]+/[0-9]+\\]|^#[0-9]+ DONE|sha256|CACHED)"; \
		printf "$(COLOR_BLUE)$(SYM_ARROW) Starting Docker build...$(COLOR_RESET)\n"; \
		if [ "$(MULTIPLATFORM)" = "true" ]; then \
			printf "$(COLOR_BLUE)$(SYM_ARROW) Building for multiple platforms: [linux/amd64, linux/arm64]$(COLOR_RESET)\n"; \
			if [ "$(DEBUG)" = "true" ]; then \
				docker buildx build --progress=plain \
					--platform linux/amd64,linux/arm64 \
					-t $(DOCKER_IMAGE) \
					--load .; \
			else \
				docker buildx build --progress=plain \
					--platform linux/amd64,linux/arm64 \
					-t $(DOCKER_IMAGE) \
					--load . 2>&1 | grep -E "$$filter" || exit 1; \
			fi; \
		else \
			printf "$(COLOR_BLUE)$(SYM_ARROW) Building for local platform$(COLOR_RESET)\n"; \
			if [ "$(DEBUG)" = "true" ]; then \
				DOCKER_BUILDKIT=1 docker build \
					--progress=plain \
					-t $(DOCKER_IMAGE) .; \
			else \
				DOCKER_BUILDKIT=1 docker build \
					--progress=plain \
					-t $(DOCKER_IMAGE) . 2>&1 | grep -E "$$filter" || exit 1; \
			fi; \
		fi && \
		printf "$(COLOR_GREEN)$(SYM_SUCCESS) Docker image build completed$(COLOR_RESET)\n" || \
		{ printf "$(COLOR_RED)$(SYM_ERROR) Docker build failed$(COLOR_RESET)\n"; exit 1; }'