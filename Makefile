.DEFAULT_GOAL := help
SHELL := /bin/bash
ENV ?= dev
TF := terraform -chdir=infra/envs/$(ENV)

.PHONY: help build test init fmt validate plan apply smoke destroy clean bootstrap-init

help: ## Show the available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

build: ## Typecheck, lint, test and bundle the Lambda handlers
	cd services && npm run check

test: ## Run the unit tests only
	cd services && npm test

bootstrap-init: ## Initialise the bootstrap root (run once, after migration)
	terraform -chdir=infra/bootstrap init -backend-config=backend.hcl -reconfigure

init: ## terraform init for ENV (default dev)
	$(TF) init -backend-config=backend.hcl -reconfigure

fmt: ## Format every Terraform file in place
	terraform fmt -recursive infra

validate: ## Validate the ENV root
	$(TF) validate

plan: build ## Build, then plan ENV into a saved plan file
	@mkdir -p infra/envs/$(ENV)/.build
	$(TF) plan -var-file=terraform.tfvars -out=tfplan

apply: ## Apply the saved plan for ENV
	$(TF) apply tfplan

smoke: ## Hit the deployed API and assert the contract
	./scripts/smoke.sh $(ENV)

destroy: ## Destroy ENV. Refuses on prod.
	@if [ "$(ENV)" = "prod" ]; then \
		echo "Refusing to destroy prod from make. Do it deliberately or not at all."; \
		exit 1; \
	fi
	$(TF) destroy -var-file=terraform.tfvars

clean: ## Remove build output
	rm -rf services/dist infra/envs/*/.build infra/envs/*/tfplan
