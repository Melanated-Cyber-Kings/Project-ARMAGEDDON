#!/bin/bash
# incident-response.sh - Lab 1b Incident Response Runbook

# ================= CONFIGURATION =================
# UPDATE THESE VALUES WITH YOUR ACTUAL RESOURCES
AWS_REGION="ap-northeast-1"                 # Change to your region
RDS_INSTANCE="lab-mysql"           # Your RDS instance name
EC2_INSTANCE_ID="i-038c0094823165402"    # Your EC2 instance ID
EC2_PUBLIC_IP="54.199.38.235"         # Your EC2 public IP
# =================================================

echo "🔴 === INCIDENT RESPONSE RUNBOOK STARTED ==="
echo ""

# 1. CHECK ALARM STATUS
echo "📊 1. CHECKING ALARM STATUS"
echo "-------------------------"
aws cloudwatch describe-alarms \
  --alarm-name-prefix "lab-db-connection-failure" \
  --query "MetricAlarms[0].[AlarmName,StateValue]" \
  --output table
echo ""

# 2. CHECK ERROR LOGS
echo "📝 2. CHECKING ERROR LOGS"
echo "------------------------"
aws logs filter-log-events \
  --log-group-name "/aws/ec2/lab-rds-app" \
  --filter-pattern "ERROR" \
  --limit 5 \
  --query "events[*].message" \
  --output text 2>/dev/null || echo "No errors found or log group doesn't exist"
echo ""

# 3. VERIFY CONFIGURATION
echo "🔧 3. VERIFYING CONFIGURATION"
echo "----------------------------"

echo "SSM Parameters:"
aws ssm get-parameters \
  --names /lab/db/endpoint /lab/db/port /lab/db/name \
  --with-decryption \
  --query "Parameters[*].[Name,Value]" \
  --output table 2>/dev/null || echo "Failed to get SSM parameters"
echo ""

echo "Secrets Manager:"
aws secretsmanager get-secret-value \
  --secret-id "lab-1a/rds/mysql" \
  --query "SecretString" \
  --output text 2>/dev/null | jq . 2>/dev/null || echo "Failed to get secret"
echo ""

# 4. CHECK INFRASTRUCTURE STATUS
echo "🏗️  4. CHECKING INFRASTRUCTURE STATUS"
echo "-----------------------------------"

echo "RDS Status:"
aws rds describe-db-instances \
  --db-instance-identifier "lab-mysql" \
  --query "DBInstances[0].[DBInstanceStatus,Endpoint.Address]" \
  --output table 2>/dev/null || echo "Failed to get RDS status"
echo ""

echo "EC2 Status:"
aws ec2 describe-instances \
  --instance-ids "i-038c0094823165402" \
  --query "Reservations[0].Instances[0].[State.Name,PublicIpAddress]" \
  --output table 2>/dev/null || echo "Failed to get EC2 status"
echo ""

# 5. TEST RECOVERY
echo "🧪 5. TESTING RECOVERY"
echo "---------------------"
echo "Testing application at http://$EC2_PUBLIC_IP/list"
echo ""

if command -v curl &> /dev/null; then
  echo "Response:"
  timeout 10 curl -s "http://$EC2_PUBLIC_IP/list" || echo "❌ Failed to connect to application"
else
  echo "⚠️  curl not installed. Test manually:"
  echo "   curl http://$EC2_PUBLIC_IP/list"
fi

echo ""
echo "✅ === RUNBOOK COMPLETED ==="
echo ""
echo "📋 NEXT STEPS:"
echo "1. Analyze the outputs above"
echo "2. Identify root cause"
echo "3. Execute recovery action"
echo "4. Re-run this script to verify recovery"