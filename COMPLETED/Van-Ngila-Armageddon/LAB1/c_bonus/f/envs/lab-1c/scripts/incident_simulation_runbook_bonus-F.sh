#!/bin/bash
# incident-response-fixed.sh

# ================= CONFIGURATION =================
AWS_REGION="ap-northeast-1"
EC2_PUBLIC_IP="54.199.38.235"  # Your EC2 IP
DOMAIN_NAME="theowafhomework.site"
APP_URL="https://app.${DOMAIN_NAME}"
# =================================================

echo "🔴 === INCIDENT RESPONSE - ENTERPRISE WORKFLOW ==="
echo ""

# Function to get timestamp for 15 minutes ago
get_timestamp_15min_ago() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    date -u -v-15M '+%Y-%m-%dT%H:%M:%SZ'
  else
    # Linux
    date -u -d '15 minutes ago' '+%Y-%m-%dT%H:%M:%SZ'
  fi
}

START_TIME=$(get_timestamp_15min_ago)
END_TIME=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# ================= STEP 1: SIGNAL TIMING CORRELATION =================
echo "📊 STEP 1 — CONFIRM SIGNAL TIMING (Last 15 minutes)"
echo "--------------------------------------------------"
echo "Time window: $START_TIME to $END_TIME"
echo ""

# Check ALB 5xx Alarm (from your Terraform)
echo "A) ALB 5xx Alarm Status:"
ALB_ALARM_NAME="${ENV_PREFIX:-lab-1c}-alb-5xx-alarm01"
aws cloudwatch describe-alarms \
  --alarm-name-prefix "$ALB_ALARM_NAME" \
  --query "MetricAlarms[0].[AlarmName,StateValue,StateUpdatedTimestamp]" \
  --output table 2>/dev/null || echo "  ⚠️  ALB alarm not found"

echo ""
echo "B) Database Error Alarm Status:"
aws cloudwatch describe-alarms \
  --alarm-name-prefix "lab-db-connection-failure" \
  --query "MetricAlarms[0].[AlarmName,StateValue,StateUpdatedTimestamp]" \
  --output table 2>/dev/null || echo "  ⚠️  DB alarm not found"
echo ""

# ================= STEP 2: ATTACK vs BACKEND DECISION =================
echo "🔍 STEP 2 — DECIDE: ATTACK vs BACKEND FAILURE"
echo "--------------------------------------------"

echo "A) WAF Analysis - Attack Indicators:"
echo "-----------------------------------"
# Get Web ACL ARN (you'll need to get this from your outputs)
echo "Checking WAF blocks in last 15 minutes..."
# Note: You'll need to set WEB_ACL_ARN or extract it from your state
# WEB_ACL_ARN="arn:aws:wafv2:ap-northeast-1:ACCOUNT:regional/webacl/..."

echo "To check WAF logs manually:"
echo "1. Go to CloudWatch Logs Insights"
echo "2. Select WAF log group: aws-waf-logs-lab-1c-webacl01"
echo "3. Run query:"
cat << 'EOF'
fields @timestamp, @message
| filter @message like /BLOCK/
| stats count() as blocks by bin(5m)
| sort @timestamp desc
EOF
echo ""

echo "B) ALB 5xx vs WAF Correlation Analysis:"
echo "--------------------------------------"
echo "If WAF BLOCKS spike aligns with ALB 5xx spike → Likely EXTERNAL ATTACK"
echo "If WAF is QUIET but ALB 5xx spikes → Likely BACKEND FAILURE"
echo ""

# Quick check for recent 5xx errors
echo "Recent ALB 5xx errors (last 15 min):"
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_ELB_5XX_Count \
  --start-time "$START_TIME" \
  --end-time "$END_TIME" \
  --period 300 \
  --statistics Sum \
  --query "Datapoints[*].[Timestamp,Sum]" \
  --output table 2>/dev/null || echo "  No 5xx metrics available"
echo ""

# ================= STEP 3: BACKEND FAILURE ANALYSIS =================
echo "🔧 STEP 3 — BACKEND FAILURE ROOT CAUSE"
echo "-------------------------------------"

echo "A) Error Classification from Application Logs:"
echo "---------------------------------------------"
aws logs filter-log-events \
  --log-group-name "/aws/ec2/lab-rds-app" \
  --start-time $(date -d '15 minutes ago' +%s)000 \
  --filter-pattern "ERROR" \
  --limit 10 \
  --query "events[*].message" \
  --output text 2>/dev/null | head -5

echo ""
echo "B) Error Pattern Matching:"
echo "-------------------------"
echo "Pattern matching in logs:"
echo "• 'Access denied' or 'authentication failed' → SECRETS DRIFT"
echo "• 'timeout' or 'no route' or 'could not connect' → NETWORK/SG ISSUE"
echo "• 'refused' → PORT/SERVICE REFUSED"
echo ""

echo "C) Retrieve Known-Good Values:"
echo "-----------------------------"
echo "1. Parameter Store values:"
aws ssm get-parameters \
  --names /lab/db/endpoint /lab/db/port /lab/db/name \
  --with-decryption \
  --query "Parameters[*].[Name,Value]" \
  --output table 2>/dev/null || echo "  Failed to get SSM parameters"
echo ""

echo "2. Secrets Manager verification:"
SECRET_ID="lab-1c/rds/mysql"
aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ID" \
  --query "SecretString" \
  --output text 2>/dev/null | jq -r '. | "Host: \(.host)\nPort: \(.port)\nDB: \(.dbname)"' 2>/dev/null || echo "  Failed to get secret"
echo ""

echo "D) Infrastructure Health Check:"
echo "------------------------------"
echo "• RDS Status:"
aws rds describe-db-instances \
  --db-instance-identifier "lab-mysql" \
  --query "DBInstances[0].[DBInstanceStatus,DBInstanceIdentifier,Endpoint.Address]" \
  --output table 2>/dev/null || echo "  RDS instance not found"
echo ""

echo "• Security Group Rules (quick check):"
echo "  Check if EC2 SG allows 3306 from itself"
echo "  Check if RDS SG allows 3306 from EC2 SG"
echo ""

# ================= STEP 4: VERIFY RECOVERY =================
echo "✅ STEP 4 — VERIFY RECOVERY"
echo "--------------------------"

echo "A) Application Health Check:"
echo "---------------------------"
echo "Testing $APP_URL/list"
if command -v curl &> /dev/null; then
  HTTP_CODE=$(timeout 10 curl -s -o /dev/null -w "%{http_code}" "$APP_URL/list" || echo "timeout")
  
  if [ "$HTTP_CODE" = "200" ]; then
    echo "  ✅ Application responding (200 OK)"
    echo "  Sample response (first 200 chars):"
    timeout 5 curl -s "$APP_URL/list" | head -c 200
    echo ""
  elif [ "$HTTP_CODE" = "500" ]; then
    echo "  ❌ Application still returning 500"
    echo "  Check: sudo tail -f /opt/rdsapp/app.log"
  else
    echo "  ⚠️  Application returned HTTP $HTTP_CODE"
  fi
else
  echo "  ⚠️  curl not available"
fi
echo ""

echo "B) Alarm Status Post-Recovery:"
echo "-----------------------------"
echo "Both alarms should return to OK state:"
echo "1. ALB 5xx Alarm: Should be OK if no 5xx errors"
echo "2. DB Connection Alarm: Should be OK if no DB errors"
echo ""

echo "C) WAF Baseline:"
echo "---------------"
echo "WAF blocks should return to normal baseline"
echo "Check CloudWatch Logs Insights with:"
cat << 'EOF'
fields @timestamp, @message
| filter @message like /BLOCK/
| stats count() as blocks by bin(1h)
| sort @timestamp desc
| limit 24
EOF
echo ""

echo "D) Final Verification Checklist:"
echo "-------------------------------"
echo "✓ [ ] Application returns 200 OK"
echo "✓ [ ] ALB 5xx alarm is in OK state"
echo "✓ [ ] DB connection alarm is in OK state"
echo "✓ [ ] WAF blocks at normal baseline"
echo "✓ [ ] Error logs show no new ERROR entries"
echo "✓ [ ] RDS instance is in 'available' state"
echo ""

# ================= CORRELATION SUMMARY =================
echo "📋 CORRELATION MATRIX SUMMARY"
echo "---------------------------"
cat << 'EOF'
SCENARIO 1: EXTERNAL ATTACK
┌──────────────┬─────────────┬─────────────┐
│   WAF        │   ALB 5xx   │   App Logs  │
├──────────────┼─────────────┼─────────────┤
│ BLOCK ↑↑↑    │ 5xx ↑↑      │ Normal      │
└──────────────┴─────────────┴─────────────┘
Action: Review WAF rules, block malicious IPs

SCENARIO 2: BACKEND FAILURE
┌──────────────┬─────────────┬─────────────┐
│   WAF        │   ALB 5xx   │   App Logs  │
├──────────────┼─────────────┼─────────────┤
│ Normal       │ 5xx ↑↑↑     │ ERROR ↑↑↑   │
└──────────────┴─────────────┴─────────────┘
Action: Check RDS, Secrets, Security Groups

SCENARIO 3: SECRETS DRIFT
┌──────────────┬─────────────┬─────────────┐
│   WAF        │   ALB 5xx   │   App Logs  │
├──────────────┼─────────────┼─────────────┤
│ Normal       │ 5xx ↑       │ "Access denied" │
└──────────────┴─────────────┴─────────────┘
Action: Rotate secrets, update app config
EOF
echo ""

echo "🚨 IMMEDIATE ACTIONS:"
echo "1. Check alarm timestamps for correlation"
echo "2. Review WAF logs for attack patterns"
echo "3. Check app logs for error classification"
echo "4. Verify infrastructure configs"
echo "5. Monitor recovery indicators"
echo ""

echo "✅ === ENTERPRISE WORKFLOW COMPLETE ==="