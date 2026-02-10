#!/bin/bash

# Ensure AWS CLI is configured
if ! command -v aws &> /dev/null; then
    echo "❌ Error: AWS CLI is not installed or not in PATH."
    exit 1
fi

echo "=== Lab 1b Completion Check ==="

# 1. Check if alarm exists
echo "1. CloudWatch Alarm:"
ALARM_NAME=$(aws cloudwatch describe-alarms --alarm-name-prefix "armageddon-class7" --query "MetricAlarms[0].AlarmName" --output text 2>/dev/null)
if [ "$ALARM_NAME" != "None" ] && [ -n "$ALARM_NAME" ]; then
    echo "✅ Exists: $ALARM_NAME"
else
    echo "❌ Missing"
fi

# 2. Check SSM parameters
echo "2. SSM Parameters:"
COUNT=$(aws ssm get-parameters --names /lab/db/host /lab/db/port /lab/db/name --query "length(Parameters)" --output text 2>/dev/null)
if [ "$COUNT" == "3" ]; then
    echo "✅ All 3 exist"
else
    echo "❌ Missing (Found: ${COUNT:-0})"
fi

# 3. Check Secrets Manager
echo "3. Secrets Manager:"
aws secretsmanager describe-secret --secret-id dakid/lab/rds/mysql --query "Name" --output text &>/dev/null && echo "✅ Exists" || echo "❌ Missing"

# 4. Check Incident Response Script
echo "4. Incident Response Script:"
[ -f "$HOME/AWS.Class7/Class7_Armageddon/my_prototype_armageddon/scripts/incident-response.sh" ] && echo "✅ Exists" || echo "❌ Missing"

# 5. Check Incident Report
echo "5. Incident Report:"
ls incident-report-*.md &>/dev/null && echo "✅ Exists" || echo "❌ Missing"

