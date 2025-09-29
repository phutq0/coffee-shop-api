TF_DIR=./
ENV?=dev
ENV_DIR=environments/$(ENV)

init:
	./scripts/init.sh $(ENV_DIR)

plan:
	./scripts/plan.sh $(ENV_DIR)

apply:
	./scripts/apply.sh $(ENV_DIR)

destroy:
	./scripts/destroy.sh $(ENV_DIR)

fmt:
	terraform fmt -recursive

validate:
	terraform -chdir=$(ENV_DIR) validate

clean:
	rm -rf $(ENV_DIR)/.terraform $(ENV_DIR)/.terraform.lock.hcl
