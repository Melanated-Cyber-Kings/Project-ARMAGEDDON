#!/bin/bash
# incident-response-fixed.sh

# ================= CONFIGURATION =================
AWS_REGION="ap-northeast-1"
EC2_PUBLIC_IP="54.199.38.235"  # Your EC2 IP
# =================================================

echo "🔴 === INCIDENT RESPONSE - DEBUG MODE ==="
echo ""

# 1. CHECK ALARM WITH DETAILS
echo "📊 1. ALARM DETAILED STATUS"
echo "--------------------------"
aws cloudwatch describe-alarms \
  --alarm-name-prefix lab-db-connection-failure \
  --query "MetricAlarms[0].[AlarmName,StateValue,StateUpdatedTimestamp,StateReason]" \
  --output table

echo ""
echo "Alarm Configuration:"
aws cloudwatch describe-alarms \
  --alarm-name-prefix lab-db-connection-failure \
  --query "MetricAlarms[0].[MetricName,Namespace,Period,EvaluationPeriods,Threshold,ComparisonOperator]" \
  --output table
echo ""

# 2. CHECK IF METRICS EXIST
echo "📈 2. METRICS AVAILABILITY"
echo "-------------------------"
echo "Checking for DBConnectionErrors metrics:"
aws cloudwatch list-metrics \
  --namespace "Lab/RDSApp" \
  --metric-name "DBConnectionErrors" \
  --query "Metrics[*].Dimensions" \
  --output table 2>/dev/null || echo "No metrics found in namespace Lab/RDSApp"

echo ""
echo "Manually pushing test metric..."
aws cloudwatch put-metric-data \
  --namespace "Lab/RDSApp" \
  --metric-name "DBConnectionErrors" \
  --value 10 \
  --dimensions LogGroupName=/aws/ec2/lab-rds-app,Test=manual

echo "Waiting 60 seconds for metric to register..."
sleep 60

echo "Checking alarm state again:"
aws cloudwatch describe-alarms \
  --alarm-name-prefix lab-db-connection-failure \
  --query "MetricAlarms[0].StateValue" \
  --output text
echo ""

# 3. CHECK APPLICATION (Handle 500 error)
echo "📱 3. APPLICATION STATUS"
echo "----------------------"
echo "Testing http://$EC2_PUBLIC_IP/list"
echo ""

if command -v curl &> /dev/null; then
  # Try health endpoint first
  HEALTH_RESPONSE=$(timeout 5 curl -s -o /dev/null -w "%{http_code}" "http://$EC2_PUBLIC_IP/list" || echo "timeout")
  
  if [ "$HEALTH_RESPONSE" = "200" ]; then
    echo "✅ Health check OK (200)"
    echo ""
    echo "Testing /list endpoint (should fail for lab):"
    curl -s "http://$EC2_PUBLIC_IP/list" | head -100
  elif [ "$HEALTH_RESPONSE" = "500" ]; then
    echo "❌ Application 500 Error - App is broken"
    echo ""
    echo "🔧 IMMEDIATE FIX NEEDED:"
    echo "1. SSH to EC2 and check logs:"
    echo "   ssh -i your-key.pem ec2-user@$EC2_PUBLIC_IP"
    echo "2. Check: sudo tail -f /var/log/web-app/app.log"
    echo "3. Common issues: Missing Python packages, DB config errors"
  elif [ "$HEALTH_RESPONSE" = "timeout" ]; then
    echo "⏱️  Application timeout - App not running or firewall blocked"
  else
    echo "⚠️  Application returned HTTP $HEALTH_RESPONSE"
  fi
else
  echo "curl not available"
fi
echo ""

# 4. FORCE ALARM STATE FOR LAB (if needed)
echo "🎯 4. LAB WORKAROUND"
echo "------------------"
echo "If metrics still not flowing, you can:"
echo ""
echo "OPTION A: Simulate alarm by setting threshold to 1 and pushing metric:"
echo "  aws cloudwatch put-metric-data \\"
echo "    --namespace 'Lab/RDSApp' \\"
echo "    --metric-name 'DBConnectionErrors' \\"
echo "    --value 1 \\"
echo "    --dimensions LogGroupName=/aws/ec2/lab-rds-app"
echo ""
echo "OPTION B: Temporarily lower alarm threshold:"
echo "  aws cloudwatch set-alarm-state \\"
echo "    --alarm-name lab-db-connection-failure \\"
echo "    --state-value ALARM \\"
echo "    --state-reason 'Manual override for lab testing'"
echo ""
echo "OPTION C: Check CloudWatch Agent is running on EC2:"
echo "  ssh -i your-key.pem ec2-user@$EC2_PUBLIC_IP"
echo "  sudo systemctl status amazon-cloudwatch-agent"
echo ""

# 5. VERIFY CLOUDWATCH AGENT
echo "🤖 5. CLOUDWATCH AGENT CHECK"
echo "--------------------------"
echo "Quick test - check if logs are being collected:"
aws logs describe-log-streams \
  --log-group-name "/aws/ec2/lab-rds-app" \
  --query "logStreams[0:3].[logStreamName,firstEventTimestamp,lastEventTimestamp]" \
  --output table 2>/dev/null || echo "No log streams found"
echo ""

# 6. CHECK ERROR LOGS
echo "📝 2. CHECKING ERROR LOGS"
echo "------------------------"
aws logs filter-log-events \
  --log-group-name "/aws/ec2/lab-rds-app" \
  --filter-pattern "ERROR" \
  --limit 5 \
  --query "events[*].message" \
  --output text 2>/dev/null || echo "No errors found or log group doesn't exist"
echo ""

# 7. VERIFY CONFIGURATION
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

# 8. CHECK INFRASTRUCTURE STATUS
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

# 9. TEST RECOVERY
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


echo "✅ === DEBUG COMPLETE ==="
echo ""
echo "🎯 SUMMARY:"
echo "1. Alarm: INSUFFICIENT_DATA = No metrics from app"
echo "2. App: 500 Error = App is broken"
echo ""
echo "🔧 ACTION PLAN:"
echo "1. Fix application 500 error first"
echo "2. Ensure app emits CloudWatch metrics on DB failure"
echo "3. Wait 5+ minutes for metrics to aggregate"
echo "4. Alarm should transition to ALARM"