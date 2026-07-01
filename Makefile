COLLECTION_NAMESPACE := david_igou
COLLECTION_NAME := devhost
COLLECTION := $(COLLECTION_NAMESPACE).$(COLLECTION_NAME)

MOLECULE_SCENARIOS := default host_prep packages podman docker container_runtimes
PROVISIONER ?= podman

.PHONY: help lint molecule molecule-kubevirt test collection-build collection-install galaxy-import clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: ## Run ansible-lint
	ansible-lint

molecule: ## Run molecule test (SCENARIO=default PROVISIONER=podman)
	PROVISIONER=$(PROVISIONER) molecule test -s $(or $(SCENARIO),default)

molecule-kubevirt: ## Run molecule test against kubevirt (SCENARIO=default)
	PROVISIONER=kubevirt molecule test -s $(or $(SCENARIO),default)

test: lint molecule ## Run lint then molecule

collection-build: ## Build the collection tarball
	ansible-galaxy collection build --force

collection-install: collection-build ## Build and install the collection locally
	ansible-galaxy collection install $(COLLECTION_NAMESPACE)-$(COLLECTION_NAME)-*.tar.gz --force

galaxy-import: ## Run galaxy-importer locally (pip install galaxy-importer)
	@echo '[galaxy-importer]\nCHECK_REQUIRED_TAGS=True' > /tmp/galaxy-importer.cfg
	GALAXY_IMPORTER_CONFIG=/tmp/galaxy-importer.cfg \
		python3 -m galaxy_importer.main --git-clone-path . --output-path /tmp

clean: ## Remove build artifacts
	rm -f $(COLLECTION_NAMESPACE)-$(COLLECTION_NAME)-*.tar.gz
