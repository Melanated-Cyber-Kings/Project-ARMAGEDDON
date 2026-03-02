#!/bin/bash
MAX_RETRIES=5
RETRY_DELAY=5

for ((i=1; i<=MAX_RETRIES; i++)); do
  terraform apply -auto-approve -var-file=lab2.auto.tfvars
  if [ $? -eq 0 ]; then
    echo "Terraform apply successful."
    break
  fi
  echo "Error occurred. Retrying in $RETRY_DELAY seconds..."
  sleep $RETRY_DELAY
  RETRY_DELAY=$((RETRY_DELAY * 2)) # Exponential backoff
done


aws secretsmanager rotate-secret --secret-id lab/rds/mysql
echo "Secret Rotated.  Ready to go."
