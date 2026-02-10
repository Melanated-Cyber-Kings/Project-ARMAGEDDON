#!/bin/bash
# incident-response.sh

echo "=== INCIDENT RESPONSE RUNBOOK ==="
echo ""
echo "1. ACKNOWLEDGE"
echo "Alarm Status:"
aws cloudwatch describe-alarms \
  --alarm-name armageddon-class7-db-connection-failure \
  --query "MetricAlarms[0].[AlarmName,StateValue]" \
  --output table

echo ""
echo "2. OBSERVE"
echo "Recent Errors from Logs:"
aws logs filter-log-events \
  --log-group-name /aws/ec2/armageddon-class7-rds-app \
  --filter-pattern "DB_CONNECT_FAIL" \
  --limit 5 \
  --query "events[*].[timestamp,message]" \
  --output table

echo ""
echo "3. VALIDATE CONFIGURATION"
echo "SSM Parameters:"
aws ssm get-parameters \
  --names /lab/db/host /lab/db/port /lab/db/name \
  --with-decryption \
  --query "Parameters[*].[Name,Value]" \
  --output table

echo ""
echo "Secrets Manager:"
aws secretsmanager get-secret-value \
  --secret-id dakid/lab/rds/mysql \
  --query "SecretString" \
  --output text | jq . 2>/dev/null || cat

echo ""
echo "4. DIAGNOSE & RECOVER"
echo ""
echo "Common Issues:"
echo "A. Check RDS Status:"
aws rds describe-db-instances \
  --db-instance-identifier armageddon-class7-rds01 \
  --query "DBInstances[0].[DBInstanceStatus,Endpoint.Address]" \
  --output table

echo ""
echo "B. Check Security Groups:"
# Note: You'll need to check your specific SG IDs
echo "Manually verify EC2 can reach RDS on port 3306"

echo ""
echo "5. VERIFY RECOVERY"
echo "Test application endpoint:"
echo "curl http://$(aws ec2 describe-instances --instance-ids i-0f1993f5b83569fceons[0].Instances[0].PublicIpAddress' --output text)/list"
