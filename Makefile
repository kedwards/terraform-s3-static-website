mkfile_path:=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))
branch_name=$(shell  git symbolic-ref -q --short HEAD | sed -e "s|^heads/||")

DEFAULT_GOAL := help

ifneq ($(VERBOSE),)
	VERBOSITY=-$(VERBOSE)
endif

ifeq ($(REGION),)
	REGION=us-east-1
endif

ifneq ($(RUNTAG),)
	RUNTAGS=--tags="$(RUNTAG)"
endif

##@ [Targets]
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

guard-%:
	@if [ "${${*}}" = "" ]; then \
  echo "Variable $* not set"; \
  exit 1; \
  fi

deploy: guard-ENV guard-REGION ## Deploy Platform, ex. make deploy ENV=<environment> REGION=<region> [RUNTAG=<tag>]
	ansible-playbook $(VERBOSITY) \
		--inventory-file=ansible/inventory.yml \
		--extra-vars="env_tag=$(ENV) env_region=$(REGION) branch_name=$(branch_name) $(EXTRA_VARS)" \
		ansible/playbook.yml $(RUNTAGS)

lint: ## Lint ansible files, ex. make lint
	@ansible-lint -p ansible/playbook.yml && \
		cfn-lint ansible/roles/*/files/*.yml

debug: ## Print debug information, ex. make debug ENV=<environment> REGION=<region> VERBOSE=vvv
	@echo "ENV: $(ENV)"
	@echo "REGION: $(REGION)"
	@echo "BRANCH_NAME: $(BRANCH_NAME)"
	@echo "TAGS: $(RUNTAGS)"
	@echo "EXTRA_VARS: $(EXTRA_VARS)"
	@echo "ROOT: $(mkfile_path)"
	@echo "VERBOSE: $(VERBOSITY)"
