# JODConverter Docker Images - Unified Makefile
.PHONY: help build build-runtime build-examples clean push start-gui start-rest stop

# Default values
REGISTRY ?= local
VERSION ?= latest
JAVA_VERSION ?= 21

help: ## Show this help message
	@echo "JODConverter Docker Images - Unified Build"
	@echo ""
	@echo "Usage: make [target] [REGISTRY=registry] [VERSION=version]"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Variables:"
	@echo "  REGISTRY      Docker registry prefix (default: local)"
	@echo "  VERSION       Image version tag (default: latest)"
	@echo "  JAVA_VERSION  Java version to use (default: 21)"
	@echo ""
	@echo "Examples:"
	@echo "  make build                                    # Build all images locally"
	@echo "  make build REGISTRY=ghcr.io/myorg            # Build with custom registry"
	@echo "  make push REGISTRY=ghcr.io/myorg             # Build and push to registry"
	@echo "  make start-gui                               # Start GUI example"
	@echo "  make start-rest                              # Start REST example"

build: ## Build all images (runtime + examples)
	./scripts/build.sh --registry $(REGISTRY) --version $(VERSION) --java-version $(JAVA_VERSION)

build-runtime: ## Build only runtime images
	./scripts/build.sh --registry $(REGISTRY) --version $(VERSION) --java-version $(JAVA_VERSION) --runtime-only

build-examples: ## Build only examples images
	./scripts/build.sh --registry $(REGISTRY) --version $(VERSION) --java-version $(JAVA_VERSION) --examples-only

push: ## Build and push all images to registry
	./scripts/build.sh --registry $(REGISTRY) --version $(VERSION) --java-version $(JAVA_VERSION) --push

clean: ## Remove all built images
	@echo "Cleaning up images..."
	-docker rmi $(REGISTRY)/jodconverter-runtime:$(VERSION) 2>/dev/null || true
	-docker rmi $(REGISTRY)/jodconverter-runtime:jre-$(VERSION) 2>/dev/null || true
	-docker rmi $(REGISTRY)/jodconverter-runtime:jdk-$(VERSION) 2>/dev/null || true
	-docker rmi $(REGISTRY)/jodconverter-examples:gui 2>/dev/null || true
	-docker rmi $(REGISTRY)/jodconverter-examples:rest 2>/dev/null || true
	-docker rmi $(REGISTRY)/jodconverter-examples:gui-$(VERSION) 2>/dev/null || true
	-docker rmi $(REGISTRY)/jodconverter-examples:rest-$(VERSION) 2>/dev/null || true
	@echo "Cleanup completed"

start-gui: stop ## Start GUI example (will build if needed)
	@if ! docker image inspect $(REGISTRY)/jodconverter-examples:gui >/dev/null 2>&1; then \
		echo "GUI image not found, building..."; \
		make build-examples REGISTRY=$(REGISTRY) VERSION=$(VERSION); \
	fi
	docker run --name jodconverter-gui --rm -p 8080:8080 --memory 512m $(REGISTRY)/jodconverter-examples:gui

start-rest: stop ## Start REST example (will build if needed)
	@if ! docker image inspect $(REGISTRY)/jodconverter-examples:rest >/dev/null 2>&1; then \
		echo "REST image not found, building..."; \
		make build-examples REGISTRY=$(REGISTRY) VERSION=$(VERSION); \
	fi
	docker run --name jodconverter-rest --rm -p 8080:8080 --memory 512m $(REGISTRY)/jodconverter-examples:rest

stop: ## Stop running containers
	-docker stop jodconverter-gui 2>/dev/null || true
	-docker stop jodconverter-rest 2>/dev/null || true

list: ## List built images
	@echo "JODConverter Images:"
	@docker images --filter=reference="$(REGISTRY)/jodconverter*" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
