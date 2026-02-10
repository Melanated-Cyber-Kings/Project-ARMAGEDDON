#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Bonus C Validation Script
# - Run from: envs/lab-1c
# - Uses terraform outputs to avoid manual ARN copying
# - Prints a human-readable report AND optionally writes markdown to deliverables
###############################################################################

REGION_DEFAULT="ap-northeast-1"
OUTFILE_DEFAULT="../../deliverables/bonus_b_cli_verification.md"

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/bonus_b_validate.sh [--region <region>] [--zone-id <Z...>] [--out <path>] [--no-write]

Examples:
  ./scripts/bonus_b_validate.sh --region ap-northeast-1 --zone-id Z103851437PNELROEQ0AM
  ./scripts/bonus_b_validate.sh --zone-id Z103851437PNELROEQ0AM --out ../../deliverables/bonus_b_cli_verification.md
  ./scripts/bonus_b_validate.sh --no-write

Notes:
  - Run this from envs/lab-1c
  - Requires: terraform, aws CLI authenticated
  - If you pass --zone-id, it will validate the Route53 alias record too.
USAGE
}

REGION="$REGION_DEFAULT"
ZONE_ID=""
OUTFILE="$OUTFILE_DEFAULT"
WRITE_OUT=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region) REGION="$2"; shift 2 ;;
    --zone-id) ZONE_ID="$2"; shift 2 ;;
    --out) OUTFILE="$2"; shift 2 ;;
    --no-write) WRITE_OUT=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing command: $1"; exit 1; }; }
need_cmd terraform
need_cmd aws

# Ensure we're in envs/lab-1c
if [[ ! -f "./01-main.tf" ]]; then
  echo "ERROR: Run this from envs/lab-1c (missing ./01-main.tf)."
  exit 1
fi

section() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

tf_out_raw() {
  local name="$1"
  terraform output -raw "$name" 2>/dev/null || true
}

# Prefer bonus_b_* outputs, fall back to legacy names
FQDN="$(tf_out_raw bonus_b_fqdn)"
ALB_ARN="$(tf_out_raw bonus_b_alb_arn)"
TG_ARN="$(tf_out_raw bonus_b_target_group_arn)"
CERT_ARN="$(tf_out_raw acm_certificate_arn)"
WAF_ARN="$(tf_out_raw waf_web_acl_arn)"
ALARM_NAME="$(tf_out_raw alb_5xx_alarm_name)"
DASH_NAME="$(tf_out_raw alb_dashboard_name)"

[[ -z "$ALB_ARN" ]] && ALB_ARN="$(tf_out_raw alb_arn)"
[[ -z "$TG_ARN" ]] && TG_ARN="$(tf_out_raw target_group_arn)"
[[ -z "$DASH_NAME" ]] && DASH_NAME="$(tf_out_raw bonus_b_dashboard_name)"
[[ -z "$ALARM_NAME" ]] && ALARM_NAME="$(tf_out_raw bonus_b_alb_5xx_alarm_name)"

if [[ -z "$FQDN" || -z "$ALB_ARN" || -z "$TG_ARN" ]]; then
  echo "ERROR: Missing required terraform outputs."
  echo "  FQDN=$FQDN"
  echo "  ALB_ARN=$ALB_ARN"
  echo "  TG_ARN=$TG_ARN"
  echo
  echo "Run: terraform output"
  exit 1
fi

# Markdown report builder (use a temp file to avoid shell escaping pain)
TMP_REPORT="$(mktemp -t bonus_b_report.XXXXXX.md)"
cleanup() { rm -f "$TMP_REPORT"; }
trap cleanup EXIT

md() { printf '%s\n' "$*" >> "$TMP_REPORT"; }
md_blank() { printf '\n' >> "$TMP_REPORT"; }
md_code() { printf '```\n%s\n```\n\n' "$*" >> "$TMP_REPORT"; }

md "# Bonus C — CLI Validation Report"
md "Generated (UTC): $(date -u +"%Y-%m-%d %H:%M:%SZ")"
md "Region: $REGION"
md_blank
md "## Terraform Outputs"
md "- FQDN: \`$FQDN\`"
md "- ALB ARN: \`$ALB_ARN\`"
md "- Target Group ARN: \`$TG_ARN\`"
[[ -n "$CERT_ARN" ]] && md "- ACM Cert ARN: \`$CERT_ARN\`"
[[ -n "$WAF_ARN" ]] && md "- WAF ARN: \`$WAF_ARN\`"
[[ -n "$ALARM_NAME" ]] && md "- Alarm Name: \`$ALARM_NAME\`"
[[ -n "$DASH_NAME" ]] && md "- Dashboard Name: \`$DASH_NAME\`"
md_blank

###############################################################################
# 1) ALB status + DNS
###############################################################################
section "ALB Status"
ALB_STATE="$(aws elbv2 describe-load-balancers --region "$REGION" --load-balancer-arns "$ALB_ARN" --query "LoadBalancers[0].State.Code" --output text)"
ALB_DNS="$(aws elbv2 describe-load-balancers --region "$REGION" --load-balancer-arns "$ALB_ARN" --query "LoadBalancers[0].DNSName" --output text)"
echo "State: $ALB_STATE"
echo "DNS:   $ALB_DNS"

md "## ALB Status"
md "- State: \`$ALB_STATE\`"
md "- DNS: \`$ALB_DNS\`"
md_blank

###############################################################################
# 2) Listeners
###############################################################################
section "ALB Listeners (80 redirect, 443 HTTPS)"
LISTENERS_TABLE="$(
  aws elbv2 describe-listeners --region "$REGION" --load-balancer-arn "$ALB_ARN" \
    --query "Listeners[].{Port:Port,Protocol:Protocol,DefaultAction:DefaultActions[0].Type}" \
    --output table
)"
echo "$LISTENERS_TABLE"
md "## ALB Listeners"
md_code "$LISTENERS_TABLE"

###############################################################################
# 3) Target health
###############################################################################
section "Target Health"
TARGET_HEALTH_TABLE="$(
  aws elbv2 describe-target-health --region "$REGION" --target-group-arn "$TG_ARN" \
    --query "TargetHealthDescriptions[].{Target:Target.Id,State:TargetHealth.State,Reason:TargetHealth.Reason,Description:TargetHealth.Description}" \
    --output table
)"
echo "$TARGET_HEALTH_TABLE"
md "## Target Health"
md_code "$TARGET_HEALTH_TABLE"

###############################################################################
# 4) WAF attached
###############################################################################
section "WAF Attached"
set +e
WAF_TABLE="$(
  aws wafv2 get-web-acl-for-resource --region "$REGION" --resource-arn "$ALB_ARN" \
    --query "WebACL.{Name:Name,Arn:ARN}" --output table 2>&1
)"
WAF_RC=$?
set -e
echo "$WAF_TABLE"

md "## WAF Attached"
md_code "$WAF_TABLE"
if [[ $WAF_RC -ne 0 ]]; then
  md "- NOTE: WAF lookup returned non-zero exit code ($WAF_RC)."
  md_blank
fi

###############################################################################
# 5) ACM certificate status (optional)
###############################################################################
section "ACM Certificate Status"
md "## ACM Certificate"
if [[ -n "$CERT_ARN" ]]; then
  CERT_STATUS="$(aws acm describe-certificate --region "$REGION" --certificate-arn "$CERT_ARN" --query "Certificate.Status" --output text)"
  echo "Certificate: $CERT_ARN"
  echo "Status:      $CERT_STATUS"
  md "- ARN: \`$CERT_ARN\`"
  md "- Status: \`$CERT_STATUS\`"
else
  echo "No Terraform output found for acm_certificate_arn (skipping)."
  md "- Not available (no Terraform output for acm_certificate_arn)."
fi
md_blank

###############################################################################
# 6) Route53 alias record (optional if zone id provided)
###############################################################################
section "Route53 Alias Record"
md "## Route53 Alias Record"
if [[ -n "$ZONE_ID" ]]; then
  R53_TABLE="$(
    aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" \
      --query "ResourceRecordSets[?Name=='${FQDN}.'].[Name,Type,AliasTarget.DNSName]" \
      --output table
  )"
  echo "$R53_TABLE"
  md_code "$R53_TABLE"
else
  echo "No --zone-id provided (skipping Route53 record lookup)."
  md "- Skipped (no --zone-id provided)."
  md_blank
fi

###############################################################################
# 7) Alarm exists (list by prefix)
###############################################################################
section "CloudWatch Alarm (contains 'alb-5xx')"
ALARMS_TABLE="$(
  aws cloudwatch describe-alarms --region "$REGION" \
    --query "MetricAlarms[?contains(AlarmName,'alb-5xx')].[AlarmName,StateValue,Threshold]" \
    --output table
)"
echo "$ALARMS_TABLE"
md "## CloudWatch Alarm"
md_code "$ALARMS_TABLE"

###############################################################################
# 8) Dashboard exists (list by prefix)
###############################################################################
section "CloudWatch Dashboard"
DASH_PREFIX="${DASH_NAME:-lab-1c-alb-dashboard}"
DASH_LIST="$(
  aws cloudwatch list-dashboards --region "$REGION" --dashboard-name-prefix "$DASH_PREFIX" \
    --query "DashboardEntries[].DashboardName" --output text
)"
echo "$DASH_LIST"
md "## CloudWatch Dashboard"
md_code "$DASH_LIST"

###############################################################################
# 9) Curl checks (best-effort)
###############################################################################
section "HTTPS/HTTP Check (curl)"
set +e
CURL_HTTPS="$(curl -I "https://${FQDN}" 2>&1)"
CURL_HTTP="$(curl -I "http://${FQDN}" 2>&1)"
set -e

echo "--- HTTPS ---"
echo "$CURL_HTTPS"
echo
echo "--- HTTP ---"
echo "$CURL_HTTP"

md "## HTTP/HTTPS (curl -I)"
md "### HTTPS"
md_code "$CURL_HTTPS"
md "### HTTP"
md_code "$CURL_HTTP"

###############################################################################
# Write report
###############################################################################
if [[ "$WRITE_OUT" -eq 1 ]]; then
  mkdir -p "$(dirname "$OUTFILE")"
  cp "$TMP_REPORT" "$OUTFILE"
  echo
  echo "Wrote markdown report to: $OUTFILE"
else
  echo
  echo "Skipping write (--no-write set)."
fi
