#!/bin/bash
set -e

echo "=== Lab 1b Phased Deployment ==="

# Check credentials
if [[ -z "$TF_VAR_db_username" || -z "$TF_VAR_db_password" ]]; then
  echo "ERROR: Set credentials first:"
  echo "  source scripts/setup.sh"
  exit 1
fi

cd terraform

# Phase 1: Network
echo "=== PHASE 1: Network ==="
terraform init
terraform apply -target=module.network -auto-approve

# Phase 2: Database
echo "=== PHASE 2: Database ==="
terraform apply -target=module.database -auto-approve

# Phase 3: Secrets
echo "=== PHASE 3: Secrets ==="
terraform apply -target=module.secrets -auto-approve

# Phase 4: Compute
echo "=== PHASE 4: Compute ==="
terraform apply -target=module.compute -auto-approve

# Wait for EC2 to initialize
echo "Waiting for EC2 initialization (60 seconds)..."
sleep 60

# Phase 5: Incident Response
echo "=== PHASE 5: Incident Response ==="
terraform apply -target=module.incident_response -auto-approve

# Phase 6: Monitoring
echo "=== PHASE 6: Monitoring ==="
terraform apply -target=module.monitoring -auto-approve

# Final: All resources
echo "=== FINAL: Complete Deployment ==="
terraform apply -auto-approve

echo "=== DEPLOYMENT COMPLETE ==="
terraform output
