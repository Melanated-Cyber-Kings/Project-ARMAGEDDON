#!/bin/bash

# Run terraform initialization
terraform init

# Apply terraform configuration
terraform apply -auto-approve

# Put the secret in AWS Secrets Manager
aws secretsmanager put-secret-value \
  --secret-id lab/rds/mysql \
  --secret-string '{"username":"admin","password":"REDACTED","dbname":"labdb", "host":"lab-mysql.fake.ap-northeast-1.rds.amazonaws.com"}'
