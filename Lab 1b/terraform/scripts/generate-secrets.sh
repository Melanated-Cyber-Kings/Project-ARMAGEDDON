#!/bin/bash
echo "=== Lab 1b Secure Secret Generation ==="

# Generate secure credentials
DB_USER="lab1b_admin_$(date +%s | tail -c 4)"
DB_PASS="Lab1b_$(openssl rand -base64 12 | tr -d '/+=' | head -c 16)"

echo "Generated credentials:"
echo "Username: $DB_USER"
echo "Password: $DB_PASS"
echo ""
echo "These will be:"
echo "1. Used to create RDS instance"
echo "2. Stored in AWS Secrets Manager"
echo "3. Retrieved by EC2 application at runtime"
echo ""

# Create a secure backup (optional)
cat > .lab1b-secrets-backup.txt << EOF
=== Lab 1b Credentials Backup ===
Generated: $(date)
Username: $DB_USER
Password: $DB_PASS

Important: These are INITIAL credentials only.
AWS Secrets Manager may rotate them automatically.
EOF

chmod 600 .lab1b-secrets-backup.txt

# Set environment variables for Terraform
export TF_VAR_db_username="$DB_USER"
export TF_VAR_db_password="$DB_PASS"

echo "Environment variables set."
echo "Credentials backed up to: .lab1b-secrets-backup.txt"
echo "Run: terraform apply -var-file='terraform.tfvars'"