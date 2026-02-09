# ============================================================
# LAB1A — Terraform Automation (Single student.env)
# ============================================================
# Student workflow:
#   cp student.env.example student.env
#   make preflight
#   make enable-ssh          # optional (detect IP + create keypair)
#   make bootstrap-secrets   # create/update secret value
#   make plan
#   make apply
#   make update-secret-host  # after RDS exists
#   make verify
#
# Notes:
# - This Makefile sources student.env and exports TF_VAR_* for Terraform.
# - It also exports AWS_REGION/AWS_DEFAULT_REGION based on TF_VAR_region.
# - detect-ip WILL write TF_VAR_ssh_ingress_cidr="<your_public_ip>/32" into student.env.
# - Terraform is ONLY run from:
#     - bootstrap/secrets
#     - bootstrap/state
#     - envs/lab-1a
#   It NEVER runs Terraform from modules/.
# ============================================================

SHELL := /bin/bash
TF ?= terraform

ROOT_DIR := $(CURDIR)

BOOTSTRAP_SECRETS := $(ROOT_DIR)/bootstrap/secrets
BOOTSTRAP_STATE   := $(ROOT_DIR)/bootstrap/state
ENV_DIR           := $(ROOT_DIR)/envs/lab-1a

# Single student config file (ignored by git)
CONFIG ?= $(ROOT_DIR)/student.env

.DEFAULT_GOAL := help

# ------------------------------------------------------------
# Internal helper: require + source student.env safely
# ------------------------------------------------------------
define REQUIRE_ENV_FILE
@if [ ! -f "$(CONFIG)" ]; then \
  echo ""; \
  echo "ERROR: Missing $(CONFIG)"; \
  echo "Create it with:"; \
  echo "  cp student.env.example student.env"; \
  echo ""; \
  exit 1; \
fi
endef

define SOURCE_ENV
set -a; source "$(CONFIG)"; set +a; \
: "$${TF_VAR_region:?ERROR: TF_VAR_region is not set in $(CONFIG)}"; \
export AWS_REGION="$$TF_VAR_region"; \
export AWS_DEFAULT_REGION="$$TF_VAR_region";
endef

# ------------------------------------------------------------
# Help
# ------------------------------------------------------------
help:
	@echo ""
	@echo "LAB1A Terraform Targets"
	@echo "-----------------------"
	@echo "preflight              → Verify AWS + Terraform are working"
	@echo "detect-ip              → Auto-detect your public IP and write TF_VAR_ssh_ingress_cidr into student.env"
	@echo "gen-ssh-key            → Create EC2 KeyPair in AWS + write PEM locally (one-time)"
	@echo "enable-ssh             → Convenience: detect-ip + gen-ssh-key"
	@echo "bootstrap-secrets      → If secret exists: update secret value; else: create via Terraform"
	@echo "bootstrap-secrets-tf   → Force Terraform apply in bootstrap/secrets"
	@echo "bootstrap-state        → Create S3/Dynamo backend (optional)"
	@echo "init                   → terraform init (env)"
	@echo "init-upgrade           → terraform init -upgrade (env)"
	@echo "validate               → terraform validate (env)"
	@echo "plan                   → terraform plan (env, outputs tfplan)"
	@echo "apply                  → terraform apply (env, uses tfplan)"
	@echo "destroy                → terraform destroy (env)"
	@echo "outputs                → terraform output (env)"
	@echo "update-secret-host     → Update secret address/host with live RDS endpoint"
	@echo "verify                 → Run AWS validation checks"
	@echo "ssh-info               → Print SSH command (if key is enabled)"
	@echo ""

# ------------------------------------------------------------
# Preflight
# ------------------------------------------------------------
preflight:
	$(call REQUIRE_ENV_FILE)
	@echo "==> Checking tools + AWS auth..."
	@bash -lc '$(SOURCE_ENV) \
	  command -v $(TF) >/dev/null || { echo "ERROR: terraform not found"; exit 1; }; \
	  command -v aws >/dev/null || { echo "ERROR: aws CLI not found"; exit 1; }; \
	  aws sts get-caller-identity --region "$$AWS_REGION" >/dev/null || { echo "ERROR: AWS auth failed"; exit 1; }; \
	  echo "OK: Terraform + AWS CLI + auth (region=$$AWS_REGION, profile=$${AWS_PROFILE:-default})"; \
	'

# ------------------------------------------------------------
# SSH helpers (student-friendly)
# ------------------------------------------------------------

# Detect public IP and persist it to CONFIG as TF_VAR_ssh_ingress_cidr="<IP>/32"
detect-ip: preflight
	@echo "==> Detecting your public IP for SSH ingress..."
	@bash -lc 'set -e; \
	  CONFIG="$(CONFIG)"; \
	  IP="$$(curl -s https://checkip.amazonaws.com || true)"; \
	  if [ -z "$$IP" ]; then IP="$$(curl -s https://api.ipify.org || true)"; fi; \
	  IP="$$(echo "$$IP" | tr -d "\n\r ")"; \
	  if [ -z "$$IP" ]; then \
	    echo "ERROR: Unable to detect public IP (curl failed)."; \
	    exit 1; \
	  fi; \
	  CIDR="$$IP/32"; \
	  echo "Detected: $$CIDR"; \
	  if grep -q "^TF_VAR_ssh_ingress_cidr=" "$$CONFIG"; then \
	    sed -i.bak "s|^TF_VAR_ssh_ingress_cidr=.*|TF_VAR_ssh_ingress_cidr=\"$$CIDR\"|g" "$$CONFIG"; \
	  else \
	    echo "" >> "$$CONFIG"; \
	    echo "TF_VAR_ssh_ingress_cidr=\"$$CIDR\"" >> "$$CONFIG"; \
	  fi; \
	  echo "Wrote TF_VAR_ssh_ingress_cidr to $$CONFIG"; \
	'

# Create EC2 KeyPair and write PEM locally (only works once per keypair name)
gen-ssh-key: preflight
	@echo "==> Creating/ensuring EC2 KeyPair + saving PEM..."
	@bash -lc '$(SOURCE_ENV) \
	  : "$${TF_VAR_ssh_key_name:?ERROR: TF_VAR_ssh_key_name not set in $(CONFIG)}"; \
	  : "$${TF_VAR_ssh_private_key_file:?ERROR: TF_VAR_ssh_private_key_file not set in $(CONFIG)}"; \
	  mkdir -p "$$(dirname "$$TF_VAR_ssh_private_key_file")"; \
	  if aws ec2 describe-key-pairs --region "$$AWS_REGION" --key-names "$$TF_VAR_ssh_key_name" >/dev/null 2>&1; then \
	    echo "KeyPair already exists in AWS: $$TF_VAR_ssh_key_name"; \
	    echo "NOTE: AWS cannot re-download the private key. If you do not have the PEM, pick a new TF_VAR_ssh_key_name."; \
	  else \
	    aws ec2 create-key-pair --region "$$AWS_REGION" --key-name "$$TF_VAR_ssh_key_name" --query "KeyMaterial" --output text > "$$TF_VAR_ssh_private_key_file"; \
	    chmod 600 "$$TF_VAR_ssh_private_key_file"; \
	    echo "Wrote PEM: $$TF_VAR_ssh_private_key_file"; \
	  fi \
	'

enable-ssh: detect-ip gen-ssh-key
	@echo "==> SSH ready: ingress restricted to your IP (/32) and keypair present."

ssh-info: preflight
	@bash -lc '$(SOURCE_ENV) \
	  IP="$$(aws ec2 describe-instances --region "$$AWS_REGION" --filters Name=tag:Lab,Values=LAB1A Name=instance-state-name,Values=running --query "Reservations[0].Instances[0].PublicIpAddress" --output text)"; \
	  echo "Public IP: $$IP"; \
	  echo "SSH: ssh -i $$TF_VAR_ssh_private_key_file ec2-user@$$IP"; \
	'

# ------------------------------------------------------------
# Bootstrap Targets
# ------------------------------------------------------------

# Lab-friendly behavior:
# - If the secret already exists, we write a new version using put-secret-value (avoids UpdateSecret+KMS edge cases).
# - If the secret does not exist, we create it via Terraform in bootstrap/secrets.
bootstrap-secrets: preflight
	@echo "==> Bootstrap secrets (create if missing; otherwise update value)..."
	@bash -lc '$(SOURCE_ENV) \
	  : "$${TF_VAR_secret_name:?ERROR: TF_VAR_secret_name is not set in $(CONFIG)}"; \
	  : "$${TF_VAR_rds_username:?ERROR: TF_VAR_rds_username is not set in $(CONFIG)}"; \
	  : "$${TF_VAR_rds_password:?ERROR: TF_VAR_rds_password is not set in $(CONFIG)}"; \
	  : "$${TF_VAR_db_name:?ERROR: TF_VAR_db_name is not set in $(CONFIG)}"; \
	  : "$${TF_VAR_port:?ERROR: TF_VAR_port is not set in $(CONFIG)}"; \
	  : "$${TF_VAR_address:?ERROR: TF_VAR_address is not set in $(CONFIG)}"; \
	  if aws secretsmanager describe-secret --region "$$AWS_REGION" --secret-id "$$TF_VAR_secret_name" >/dev/null 2>&1; then \
	    echo "Secret exists: $$TF_VAR_secret_name (writing new secret version)"; \
	    aws secretsmanager put-secret-value \
	      --region "$$AWS_REGION" \
	      --secret-id "$$TF_VAR_secret_name" \
	      --secret-string "{ \
	        \"username\":\"$$TF_VAR_rds_username\", \
	        \"password\":\"$$TF_VAR_rds_password\", \
	        \"address\":\"$$TF_VAR_address\", \
	        \"host\":\"$$TF_VAR_address\", \
	        \"port\":$${TF_VAR_port:-3306}, \
	        \"dbname\":\"$${TF_VAR_db_name:-labdb}\" \
	      }" >/dev/null; \
	    echo "OK: wrote new secret version (address/host may be placeholder until RDS deploy)"; \
	  else \
	    echo "Secret not found: $$TF_VAR_secret_name (creating via Terraform in bootstrap/secrets)"; \
	    cd "$(BOOTSTRAP_SECRETS)" && \
	    $(TF) init && \
	    $(TF) plan -out=tfplan && \
	    $(TF) apply tfplan; \
	  fi \
	'

bootstrap-secrets-tf: preflight
	@echo "==> Running Secrets bootstrap via Terraform (force)..."
	@bash -lc '$(SOURCE_ENV) \
	  cd "$(BOOTSTRAP_SECRETS)" && \
	  $(TF) init && \
	  $(TF) plan -out=tfplan && \
	  $(TF) apply tfplan \
	'

bootstrap-state: preflight
	@echo "==> Running Backend bootstrap (optional)..."
	@bash -lc '$(SOURCE_ENV) \
	  cd "$(BOOTSTRAP_STATE)" && \
	  $(TF) init && \
	  $(TF) plan -out=tfplan && \
	  $(TF) apply tfplan \
	'

# ------------------------------------------------------------
# Environment Targets
# ------------------------------------------------------------
init: preflight
	@echo "==> terraform init (env)"
	@bash -lc '$(SOURCE_ENV) cd "$(ENV_DIR)" && $(TF) init'

init-upgrade: preflight
	@echo "==> terraform init -upgrade (env)"
	@bash -lc '$(SOURCE_ENV) cd "$(ENV_DIR)" && $(TF) init -upgrade'

validate: preflight
	@echo "==> terraform validate (env)"
	@bash -lc '$(SOURCE_ENV) cd "$(ENV_DIR)" && $(TF) validate'

plan: preflight
	@echo "==> terraform plan (env)"
	@bash -lc '$(SOURCE_ENV) \
	  cd "$(ENV_DIR)" && \
	  $(TF) init && \
	  $(TF) plan -out=tfplan \
	'

apply: preflight
	@echo "==> terraform apply (env)"
	@bash -lc '$(SOURCE_ENV) \
	  cd "$(ENV_DIR)" && \
	  if [ ! -f tfplan ]; then \
	    echo "tfplan not found — running plan first..."; \
	    $(TF) init && $(TF) plan -out=tfplan; \
	  fi; \
	  $(TF) apply tfplan \
	'

destroy: preflight
	@echo "==> terraform destroy (env)"
	@bash -lc '$(SOURCE_ENV) cd "$(ENV_DIR)" && $(TF) destroy'

outputs: preflight
	@echo "==> terraform output (env)"
	@bash -lc '$(SOURCE_ENV) cd "$(ENV_DIR)" && $(TF) output'

# ------------------------------------------------------------
# Post-deploy: update secret address/host with real RDS endpoint
# ------------------------------------------------------------
update-secret-host: preflight
	@echo "==> Updating secret address/host using current RDS endpoint..."
	@bash -lc '$(SOURCE_ENV) \
	  : "$${TF_VAR_secret_name:?ERROR: TF_VAR_secret_name is not set in $(CONFIG)}"; \
	  RDS_ENDPOINT="$$(aws rds describe-db-instances --region "$$AWS_REGION" --query "DBInstances[0].Endpoint.Address" --output text)"; \
	  if [ -z "$$RDS_ENDPOINT" ] || [ "$$RDS_ENDPOINT" = "None" ]; then \
	    echo "ERROR: Could not resolve RDS endpoint. Is RDS deployed yet?"; \
	    exit 1; \
	  fi; \
	  aws secretsmanager put-secret-value \
	    --region "$$AWS_REGION" \
	    --secret-id "$$TF_VAR_secret_name" \
	    --secret-string "{ \
	      \"username\":\"$$TF_VAR_rds_username\", \
	      \"password\":\"$$TF_VAR_rds_password\", \
	      \"address\":\"$$RDS_ENDPOINT\", \
	      \"host\":\"$$RDS_ENDPOINT\", \
	      \"port\":$${TF_VAR_port:-3306}, \
	      \"dbname\":\"$${TF_VAR_db_name:-labdb}\" \
	    }" >/dev/null; \
	  echo "Updated $$TF_VAR_secret_name address/host => $$RDS_ENDPOINT"; \
	'

# ------------------------------------------------------------
# Instructor / Validation Helpers
# ------------------------------------------------------------
verify: preflight
	@echo ""
	@echo "==> EC2"
	@bash -lc '$(SOURCE_ENV) \
	  aws ec2 describe-instances \
	    --region "$$AWS_REGION" \
	    --filters Name=tag:Lab,Values=LAB1A Name=instance-state-name,Values=running \
	    --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name,PublicIP:PublicIpAddress,IAM:IamInstanceProfile.Arn,SGs:SecurityGroups[].GroupId,Key:KeyName}" \
	    --output table \
	'

	@echo ""
	@echo "==> RDS"
	@bash -lc '$(SOURCE_ENV) \
	  aws rds describe-db-instances \
	    --region "$$AWS_REGION" \
	    --query "DBInstances[].{ID:DBInstanceIdentifier,Status:DBInstanceStatus,Public:PubliclyAccessible,MultiAZ:MultiAZ,Encrypted:StorageEncrypted,Endpoint:Endpoint.Address,Port:Endpoint.Port}" \
	    --output table \
	'

	@echo ""
	@echo "==> Secret (metadata only)"
	@bash -lc '$(SOURCE_ENV) \
	  aws secretsmanager describe-secret \
	    --region "$$AWS_REGION" \
	    --secret-id "$$TF_VAR_secret_name" \
	    --query "{Name:Name,KmsKeyId:KmsKeyId,RotationEnabled:RotationEnabled}" \
	    --output table \
	'

.PHONY: help preflight detect-ip gen-ssh-key enable-ssh ssh-info \
        bootstrap-secrets bootstrap-secrets-tf bootstrap-state \
        init init-upgrade validate plan apply destroy outputs update-secret-host verify
