#!/usr/bin/env bash
set -euo pipefail

# Disable AWS CLI pager (prevents "stuck in less" when output is long)
export AWS_PAGER=""
export AWS_CLI_AUTO_PROMPT=off
export PAGER=cat


###############################################################################
# Bonus D — Validation Script (Lab 1C)
# - Prints a markdown report to stdout by default
# - Optionally writes a deliverable file (with safe timestamp rotation)
# - Uses DNS lookup proof via dig (NOT tfvars)
#
# Requirements: terraform, aws, dig, curl
#
# Usage:
#   ./scripts/bonus_d_validate.sh
#   ./scripts/bonus_d_validate.sh --write
#   ./scripts/bonus_d_validate.sh --write --out ../../deliverables/bonus_d_validation.md
#   ./scripts/bonus_d_validate.sh --no-file
#   ./scripts/bonus_d_validate.sh --region ap-northeast-1
#   ./scripts/bonus_d_validate.sh --help
###############################################################################

SCRIPT_NAME="$(basename "$0")"
TF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DELIVERABLE_DIR="$(cd "$TF_DIR/../../deliverables" 2>/dev/null && pwd || true)"

REGION_DEFAULT=""
OUTFILE_DEFAULT="${DELIVERABLE_DIR:-$TF_DIR}/bonus_d_validation.md"

WRITE_FILE=false
NO_FILE=false
OUTFILE="$OUTFILE_DEFAULT"
REGION="$REGION_DEFAULT"

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/bonus_d_validate.sh [options]

Options:
  --write                 Write report to file (default: off)
  --out <path>            Output file path (default: ../../deliverables/bonus_d_validation.md)
  --no-file               Never write a file (stdout only)
  --region <region>       Override AWS region (default: terraform output/var or AWS config)
  -h, --help              Show help

Notes:
- Script prints the full markdown report to stdout even when writing a file.
- If --write is used and the output file exists, a timestamped file is created.
- FQDN is proven via DNS lookup (dig), not from tfvars.
USAGE
}

log() { echo "[INFO] $*" >&2; }
warn() { echo "[WARN] $*" >&2; }

need_cmd() {
  local c="$1"
  command -v "$c" >/dev/null 2>&1 || { warn "Missing command: $c (some checks may be skipped)"; return 1; }
  return 0
}

# Capture command output without failing the whole script.
cap() {
  # cap VAR_NAME command...
  local __var="$1"; shift
  local __out=""
  set +e
  __out="$("$@" 2>/dev/null)"
  local __rc=$?
  set -e
  printf -v "$__var" "%s" "$__out"
  return $__rc
}

status_icon() {
  local v="${1:-}"
  if [[ -n "$v" && "$v" != "<missing>" && "$v" != "None" && "$v" != "<empty>" && "$v" != "<not configured>" ]]; then
    echo "🟢"
  else
    echo "🔴"
  fi
}

utc_now() { date -u +"%Y-%m-%d %H:%M:%SZ"; }
utc_stamp() { date -u +"%Y%m%dT%H%M%SZ"; }

# -----------------------------
# Parse args
# -----------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --write) WRITE_FILE=true; shift ;;
    --no-file) NO_FILE=true; shift ;;
    --out) OUTFILE="$2"; shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) warn "Unknown option: $1"; usage; exit 2 ;;
  esac
done

log "$SCRIPT_NAME starting..."
log "TF_DIR=$TF_DIR"
log "DELIVERABLE_DIR=${DELIVERABLE_DIR:-<none>}"
log "NO_FILE=$NO_FILE  WRITE_FILE=$WRITE_FILE"
log "OUTFILE=$OUTFILE"

# -----------------------------
# Determine region
# -----------------------------
if [[ -z "${REGION}" ]]; then
  # 1) try terraform output region (if present)
  if cap TF_REGION terraform -chdir="$TF_DIR" output -raw region; then
    REGION="$TF_REGION"
  fi
fi

if [[ -z "${REGION}" ]]; then
  # 2) try AWS config
  if cap AWS_CFG_REGION aws configure get region; then
    REGION="${AWS_CFG_REGION}"
  fi
fi

if [[ -z "${REGION}" ]]; then
  REGION="ap-northeast-1"
  warn "Region not detected; defaulting to $REGION"
fi

# -----------------------------
# Terraform outputs (root)
# -----------------------------
tf_out_raw() {
  local name="$1"
  local v=""
  if cap v terraform -chdir="$TF_DIR" output -raw "$name"; then
    if [[ -n "$v" ]]; then echo "$v"; return 0; fi
  fi
  echo "<missing>"
  return 1
}

# -----------------------------
# Resolve application FQDN (canonical first, legacy fallback)
# -----------------------------
FQDN_TF="$(tf_out_raw app_fqdn)"

if [[ "$FQDN_TF" == "<missing>" ]]; then
  FQDN_TF="$(tf_out_raw bonus_c_fqdn)"
fi

if [[ "$FQDN_TF" == "<missing>" ]]; then
  FQDN_TF="$(tf_out_raw bonus_b_fqdn)"
fi


ALB_ARN="$(tf_out_raw alb_arn)"
ALB_DNS="$(tf_out_raw alb_dns_name)"
TG_ARN="$(tf_out_raw target_group_arn)"
CERT_ARN="$(tf_out_raw acm_certificate_arn)"
WAF_ARN_TF="$(tf_out_raw waf_web_acl_arn)"
SNS_TOPIC_ARN="$(tf_out_raw sns_topic_arn)"
ALARM_NAME="$(tf_out_raw alb_5xx_alarm_name)"
DASHBOARD_NAME="$(tf_out_raw alb_dashboard_name)"
ROUTE53_ZONE_ID="$(tf_out_raw route53_zone_id)"

# -----------------------------
# DNS lookup proof (dig)
# -----------------------------
DNS_FQDN="<missing>"
DNS_A_SHORT="<missing>"

if need_cmd dig; then
  # Prefer TF output for the FQDN string, but the proof is dig itself.
  if [[ "$FQDN_TF" != "<missing>" ]]; then
    DNS_FQDN="$FQDN_TF"
  fi

  if [[ "$DNS_FQDN" != "<missing>" ]]; then
    cap DNS_A_SHORT dig "$DNS_FQDN" +short || true
    DNS_A_SHORT="${DNS_A_SHORT:-<missing>}"
  fi
fi

# -----------------------------
# ALB status / listeners / target health
# -----------------------------
ALB_NAME="<missing>"
ALB_SCHEME="<missing>"
ALB_STATE="<missing>"
ALB_DNS_DESCRIBE="<missing>"

if [[ "$ALB_ARN" != "<missing>" ]] && need_cmd aws; then
  cap ALB_NAME aws --no-cli-pager elbv2 describe-load-balancers --region "$REGION" \
    --load-balancer-arns "$ALB_ARN" --query 'LoadBalancers[0].LoadBalancerName' --output text || true

  cap ALB_SCHEME aws --no-cli-pager elbv2 describe-load-balancers --region "$REGION" \
    --load-balancer-arns "$ALB_ARN" --query 'LoadBalancers[0].Scheme' --output text || true

  cap ALB_STATE aws --no-cli-pager elbv2 describe-load-balancers --region "$REGION" \
    --load-balancer-arns "$ALB_ARN" --query 'LoadBalancers[0].State.Code' --output text || true

  cap ALB_DNS_DESCRIBE aws --no-cli-pager elbv2 describe-load-balancers --region "$REGION" \
    --load-balancer-arns "$ALB_ARN" --query 'LoadBalancers[0].DNSName' --output text || true
fi

LISTENERS_TABLE="<missing>"
if [[ "$ALB_ARN" != "<missing>" ]] && need_cmd aws; then
  cap LISTENERS_TABLE aws --no-cli-pager elbv2 describe-listeners --region "$REGION" \
    --load-balancer-arn "$ALB_ARN" --output table || true
fi

TARGET_HEALTH_TABLE="<missing>"
if [[ "$TG_ARN" != "<missing>" ]] && need_cmd aws; then
  cap TARGET_HEALTH_TABLE aws --no-cli-pager elbv2 describe-target-health --region "$REGION" \
    --target-group-arn "$TG_ARN" --output table || true
fi

# -----------------------------
# ACM certificate status
# -----------------------------
CERT_STATUS="<missing>"
CERT_DOMAIN="<missing>"
CERT_NOT_AFTER="<missing>"
CERT_DVO_TABLE="<missing>"

if [[ "$CERT_ARN" != "<missing>" ]] && need_cmd aws; then
  cap CERT_STATUS aws --no-cli-pager acm describe-certificate --region "$REGION" \
    --certificate-arn "$CERT_ARN" --query 'Certificate.Status' --output text || true

  cap CERT_DOMAIN aws --no-cli-pager acm describe-certificate --region "$REGION" \
    --certificate-arn "$CERT_ARN" --query 'Certificate.DomainName' --output text || true

  cap CERT_NOT_AFTER aws --no-cli-pager acm describe-certificate --region "$REGION" \
    --certificate-arn "$CERT_ARN" --query 'Certificate.NotAfter' --output text || true

  cap CERT_DVO_TABLE aws --no-cli-pager acm describe-certificate --region "$REGION" \
    --certificate-arn "$CERT_ARN" \
    --query 'Certificate.DomainValidationOptions[0].{Domain:DomainName,Name:ResourceRecord.Name,Type:ResourceRecord.Type,Value:ResourceRecord.Value}' \
    --output table || true
fi

# -----------------------------
# WAF attached + logging (+log group validation)
# -----------------------------
WAF_ARN_ATTACHED="<missing>"
WAF_NAME_ATTACHED="<missing>"
WAF_LOG_DEST="<not configured>"
WAF_LOG_JSON="<empty>"

WAF_LOG_GROUP_NAME="<missing>"
WAF_LOG_GROUP_ARN="<missing>"
WAF_LOG_GROUP_RETENTION="<missing>"
WAF_LOG_GROUP_FOUND="<missing>"
WAF_LOG_MATCH="<missing>"

if [[ "$ALB_ARN" != "<missing>" ]] && need_cmd aws; then
  if cap WAF_ARN_ATTACHED aws --no-cli-pager wafv2 get-web-acl-for-resource --region "$REGION" \
      --resource-arn "$ALB_ARN" --query 'WebACL.ARN' --output text; then
    cap WAF_NAME_ATTACHED aws --no-cli-pager wafv2 get-web-acl-for-resource --region "$REGION" \
      --resource-arn "$ALB_ARN" --query 'WebACL.Name' --output text || true
  else
    WAF_ARN_ATTACHED="<missing>"
    WAF_NAME_ATTACHED="<missing>"
  fi
fi

# WAF logging config: NEVER fail the whole script if not configured.
if [[ "$WAF_ARN_TF" != "<missing>" ]] && need_cmd aws; then
  if cap WAF_LOG_DEST aws --no-cli-pager wafv2 get-logging-configuration --region "$REGION" \
      --resource-arn "$WAF_ARN_TF" --query 'LoggingConfiguration.LogDestinationConfigs[0]' --output text; then
    [[ -n "$WAF_LOG_DEST" ]] || WAF_LOG_DEST="<not configured>"
    cap WAF_LOG_JSON aws --no-cli-pager wafv2 get-logging-configuration --region "$REGION" \
      --resource-arn "$WAF_ARN_TF" --output json || true
    [[ -n "$WAF_LOG_JSON" ]] || WAF_LOG_JSON="<empty>"
  else
    WAF_LOG_DEST="<not configured>"
    WAF_LOG_JSON="<empty>"
  fi
fi

# Validate CloudWatch log group exists and matches the WAF log destination ARN
if [[ "$WAF_LOG_DEST" != "<not configured>" && "$WAF_LOG_DEST" != "<missing>" ]] && need_cmd aws; then
  # Destination is typically a CW Logs log group ARN; derive the name from it.
  if [[ "$WAF_LOG_DEST" == *":log-group:"* ]]; then
    WAF_LOG_GROUP_NAME="${WAF_LOG_DEST##*:log-group:}"
  fi

  if [[ "$WAF_LOG_GROUP_NAME" != "<missing>" ]]; then
    if cap WAF_LOG_GROUP_ARN aws --no-cli-pager logs describe-log-groups --region "$REGION" \
        --log-group-name-prefix "$WAF_LOG_GROUP_NAME" --query 'logGroups[0].arn' --output text; then
      cap WAF_LOG_GROUP_RETENTION aws --no-cli-pager logs describe-log-groups --region "$REGION" \
        --log-group-name-prefix "$WAF_LOG_GROUP_NAME" --query 'logGroups[0].retentionInDays' --output text || true
      WAF_LOG_GROUP_FOUND="yes"
    else
      WAF_LOG_GROUP_FOUND="no"
    fi

    if [[ "$WAF_LOG_GROUP_FOUND" == "yes" && "$WAF_LOG_GROUP_ARN" != "<missing>" && "$WAF_LOG_GROUP_ARN" != "None" ]]; then
      if [[ "$WAF_LOG_DEST" == "$WAF_LOG_GROUP_ARN" ]]; then
        WAF_LOG_MATCH="matches log group ARN"
      else
        WAF_LOG_MATCH="does NOT match log group ARN"
      fi
    fi
  fi
fi

# -----------------------------
# CloudWatch alarm + dashboard existence (AWS-side)
# -----------------------------
ALARM_EXISTS="<missing>"
ALARM_ACTIONS="<missing>"
if [[ "$ALARM_NAME" != "<missing>" ]] && need_cmd aws; then
  if cap ALARM_EXISTS aws --no-cli-pager cloudwatch describe-alarms --region "$REGION" \
      --alarm-names "$ALARM_NAME" --query 'MetricAlarms[0].AlarmName' --output text; then
    cap ALARM_ACTIONS aws --no-cli-pager cloudwatch describe-alarms --region "$REGION" \
      --alarm-names "$ALARM_NAME" --query 'MetricAlarms[0].AlarmActions' --output text || true
  else
    ALARM_EXISTS="<missing>"
  fi
fi

DASHBOARD_EXISTS="<missing>"
if [[ "$DASHBOARD_NAME" != "<missing>" ]] && need_cmd aws; then
  if cap DASHBOARD_EXISTS aws --no-cli-pager cloudwatch list-dashboards --region "$REGION" \
      --dashboard-name-prefix "$DASHBOARD_NAME" --query 'DashboardEntries[0].DashboardName' --output text; then
    true
  else
    DASHBOARD_EXISTS="<missing>"
  fi
fi

# -----------------------------
# SNS subscription check
# -----------------------------
SNS_SUBS_TABLE="<missing>"
if [[ "$SNS_TOPIC_ARN" != "<missing>" ]] && need_cmd aws; then
  cap SNS_SUBS_TABLE aws --no-cli-pager sns list-subscriptions-by-topic --region "$REGION" \
    --topic-arn "$SNS_TOPIC_ARN" --output table || true
fi

# -----------------------------
# HTTP/HTTPS checks
# -----------------------------
HTTP_STATUS="<missing>"
HTTPS_STATUS="<missing>"

if need_cmd curl && [[ "$DNS_FQDN" != "<missing>" ]]; then
  cap HTTPS_STATUS bash -lc "curl -sS -I https://$DNS_FQDN | head -n 1" || true
  cap HTTP_STATUS  bash -lc "curl -sS -I http://$DNS_FQDN  | head -n 1" || true
  HTTPS_STATUS="${HTTPS_STATUS:-<missing>}"
  HTTP_STATUS="${HTTP_STATUS:-<missing>}"
fi

###############################################################################
# Bonus D Validation: Route53 apex + ALB access logs
# Run from: envs/lab-1c
###############################################################################

tf_out() {
  terraform output -raw "$1" 2>/dev/null || true
}

echo ""
echo "=============================="
echo "BONUS D: Apex ALIAS + ALB Access Logs"
echo "=============================="

# Addresses a problem created by not standardizing the apex domain output name in env outputs. 
# Eventually we should have a consistent output name for the apex domain (e.g. "domain_name") 
# in the root module outputs, but for now we try to be flexible in reading it.


# DOMAIN_NAME="$(tf_out domain_name)"
DOMAIN_NAME="$(tf_out_raw apex_fqdn)"
if [[ "$DOMAIN_NAME" == "<missing>" ]]; then
  # fallback: derive from app fqdn
  DOMAIN_NAME="${FQDN_TF#app.}"
fi

# These outputs may or may not exist in your env outputs; adjust names if needed.
ZONE_ID="$(tf_out route53_zone_id)"
ALB_ARN="$(tf_out alb_arn)"
ALB_DNS="$(tf_out alb_dns_name)"
LOG_BUCKET="$(tf_out alb_logs_bucket_name)"
LOG_PREFIX="$(tf_out alb_access_logs_prefix)"

# Fallbacks if some outputs aren't defined in env outputs
if [[ -z "${LOG_PREFIX}" ]]; then
  LOG_PREFIX="alb-access-logs"
fi

if [[ -z "${DOMAIN_NAME}" ]]; then
  echo "ERROR: Could not read terraform output 'domain_name'. Add it as an output or set DOMAIN_NAME manually."
  exit 1
fi

echo "Domain: ${DOMAIN_NAME}"
echo "Zone ID: ${ZONE_ID:-<missing>}"
echo "ALB ARN: ${ALB_ARN:-<missing>}"
echo "ALB DNS: ${ALB_DNS:-<missing>}"
echo "Log bucket: ${LOG_BUCKET:-<missing>}"
echo "Log prefix: ${LOG_PREFIX}"

echo ""
echo "[D1] Verify apex Route53 record exists (requires Zone ID)"
if [[ -n "${ZONE_ID}" ]]; then
  aws route53 list-resource-record-sets \
    --hosted-zone-id "${ZONE_ID}" \
    --query "ResourceRecordSets[?Name=='${DOMAIN_NAME}.']" \
    --output json
  echo "OK: Route53 query executed. Confirm record shows ALIAS to ALB."
else
  echo "SKIP: ZONE_ID missing. Add terraform output for zone id or set it in the script."
fi

echo ""
echo "[D2] Verify ALB access logging attributes (requires ALB ARN)"
if [[ -n "${ALB_ARN}" ]]; then
  aws --no-cli-pager elbv2 describe-load-balancer-attributes \
    --region "${REGION}" \
    --load-balancer-arn "${ALB_ARN}" \
    --query "Attributes[?starts_with(Key,'access_logs.s3')].[Key,Value]" \
    --output table

  echo "Expected:"
  echo " - access_logs.s3.enabled = true"
  echo " - access_logs.s3.bucket  = ${LOG_BUCKET}"
  echo " - access_logs.s3.prefix  = ${LOG_PREFIX}"
else
  echo "SKIP: ALB_ARN missing. Add terraform output for ALB ARN or set it in the script."
fi

echo ""
echo "[D3] Generate traffic (HEAD requests)"
set +e
curl -sS -I "https://${DOMAIN_NAME}" | head -n 5
curl -sS -I "https://app.${DOMAIN_NAME}" | head -n 5
set -e
echo "OK: Traffic generated (even if curl fails, it still attempted)."

echo ""
echo "[D4] Check S3 for access logs (may take a few minutes)"
if [[ -n "${LOG_BUCKET}" ]]; then
  ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
  echo "Account ID: ${ACCOUNT_ID}"
  echo "Listing: s3://${LOG_BUCKET}/${LOG_PREFIX}/AWSLogs/${ACCOUNT_ID}/elasticloadbalancing/"

  aws s3 ls "s3://${LOG_BUCKET}/${LOG_PREFIX}/AWSLogs/${ACCOUNT_ID}/elasticloadbalancing/" --recursive | head || true

  echo "NOTE: ALB access logs can lag. If empty, retry in 5–10 minutes after generating traffic."
else
  echo "SKIP: LOG_BUCKET missing. Ensure module outputs expose alb_logs_bucket_name and env outputs pass it through."
fi


# -----------------------------
# Build markdown report
# -----------------------------
GENERATED_UTC="$(utc_now)"

FQDN_STATUS="$(status_icon "$DNS_FQDN")"
ALB_NAME_STATUS="$(status_icon "$ALB_NAME")"
ALB_ARN_STATUS="$(status_icon "$ALB_ARN")"
TG_ARN_STATUS="$(status_icon "$TG_ARN")"
CERT_ARN_STATUS="$(status_icon "$CERT_ARN")"
WAF_TF_STATUS="$(status_icon "$WAF_ARN_TF")"
WAF_ATT_STATUS="$(status_icon "$WAF_ARN_ATTACHED")"
SNS_STATUS="$(status_icon "$SNS_TOPIC_ARN")"
ALARM_STATUS="$(status_icon "$ALARM_NAME")"
DASH_STATUS="$(status_icon "$DASHBOARD_NAME")"
ZONE_STATUS="$(status_icon "$ROUTE53_ZONE_ID")"

DNS_A_STATUS="$(status_icon "$DNS_A_SHORT")"

# One-line DNS A output
DNS_A_ONE_LINE="$(echo "$DNS_A_SHORT" | tr '\n' ' ' | sed 's/[[:space:]]\+$//')"

REPORT="$(
cat <<EOF
# Bonus C — Validation Report
Generated (UTC): \`$GENERATED_UTC\`
Region: \`$REGION\`

## Terraform Outputs (root)

| Component | Status | Value |
|---|---:|---|
| **FQDN (via DNS lookup)** | $FQDN_STATUS | \`$DNS_FQDN\` |
| **ALB Name** | $ALB_NAME_STATUS | \`$ALB_NAME\` |
| **ALB ARN** | $ALB_ARN_STATUS | \`$ALB_ARN\` |
| **Target Group ARN** | $TG_ARN_STATUS | \`$TG_ARN\` |
| **ACM Cert ARN** | $CERT_ARN_STATUS | \`$CERT_ARN\` |
| **WAF ARN (tf output)** | $WAF_TF_STATUS | \`$WAF_ARN_TF\` |
| **WAF ARN (attached)** | $WAF_ATT_STATUS | \`$WAF_ARN_ATTACHED\` |
| **SNS Topic ARN** | $SNS_STATUS | \`$SNS_TOPIC_ARN\` |
| **ALB 5xx Alarm Name** | $ALARM_STATUS | \`$ALARM_NAME\` |
| **Dashboard Name** | $DASH_STATUS | \`$DASHBOARD_NAME\` |
| **Route53 Zone ID (resolved)** | $ZONE_STATUS | \`$ROUTE53_ZONE_ID\` |

## DNS Resolution Evidence

| Check | Status | Command | Result |
|---|---:|---|---|
| **FQDN A record** | $DNS_A_STATUS | \`dig $DNS_FQDN +short\` | \`$DNS_A_ONE_LINE\` |

## ALB Status
- Scheme: \`$ALB_SCHEME\` (expected: internet-facing)
- State: \`$ALB_STATE\` (expected: active)
- DNS: \`$ALB_DNS_DESCRIBE\`

## ALB Listeners
\`\`\`
$LISTENERS_TABLE
\`\`\`

## Target Health
\`\`\`
$TARGET_HEALTH_TABLE
\`\`\`

## ACM Certificate
- Status: \`$CERT_STATUS\` (expected: ISSUED)
- DomainName: \`$CERT_DOMAIN\`
- NotAfter: \`$CERT_NOT_AFTER\`

### Validation Options (records ACM expects)
\`\`\`
$CERT_DVO_TABLE
\`\`\`

## WAF Attached + Logging
- Attached: $(status_icon "$WAF_NAME_ATTACHED") \`$WAF_NAME_ATTACHED\`
- WebACL ARN: \`$WAF_ARN_TF\`
- Logging Destination: \`$WAF_LOG_DEST\`

### WAF Logging Configuration (raw JSON)
\`\`\`
$WAF_LOG_JSON
\`\`\`

### WAF CloudWatch Log Group Validation

| Check | Status | Value |
|---|---:|---|
| **Log group name (derived)** | $(status_icon "$WAF_LOG_GROUP_NAME") | \`$WAF_LOG_GROUP_NAME\` |
| **Log group exists** | $(status_icon "$WAF_LOG_GROUP_FOUND") | \`$WAF_LOG_GROUP_FOUND\` |
| **Log group ARN** | $(status_icon "$WAF_LOG_GROUP_ARN") | \`$WAF_LOG_GROUP_ARN\` |
| **Retention (days)** | $(status_icon "$WAF_LOG_GROUP_RETENTION") | \`$WAF_LOG_GROUP_RETENTION\` |
| **Destination ARN match** | $(status_icon "$WAF_LOG_MATCH") | \`$WAF_LOG_MATCH\` |

## CloudWatch Alarm (ALB 5xx) + SNS actions
- Alarm exists: \`$ALARM_EXISTS\`
- Alarm actions: \`$ALARM_ACTIONS\`

## CloudWatch Dashboard
- Dashboard output: \`$DASHBOARD_NAME\`
- Exists: \`$DASHBOARD_EXISTS\`

## SNS Subscriptions (mandatory)
\`\`\`
$SNS_SUBS_TABLE
\`\`\`

## HTTP/HTTPS (curl -I)
- HTTPS: \`$HTTPS_STATUS\`
- HTTP:  \`$HTTP_STATUS\`

## Help
- If DNS is 🔴: confirm ALIAS exists and wait for propagation; re-run \`dig $DNS_FQDN +short\`
- If WAF logging is 🔴: ensure \`aws_wafv2_web_acl_logging_configuration\` exists and CW log group name begins with \`aws-waf-logs-\`
- If alarm/dashboard missing: confirm ingress module created them and root outputs reference module outputs
EOF
)"


# -----------------------------
# Output to stdout
# -----------------------------
echo "$REPORT"

# -----------------------------
# Optional file write (timestamp rotation)
# -----------------------------
if [[ "$NO_FILE" == "true" ]]; then
  exit 0
fi

if [[ "$WRITE_FILE" == "true" ]]; then
  mkdir -p "$(dirname "$OUTFILE")" 2>/dev/null || true

  FILE_TO_WRITE="$OUTFILE"
  if [[ -f "$OUTFILE" ]]; then
    base="${OUTFILE%.*}"
    ext="${OUTFILE##*.}"
    if [[ "$ext" == "$OUTFILE" ]]; then
      FILE_TO_WRITE="${OUTFILE}.$(utc_stamp)"
    else
      FILE_TO_WRITE="${base}.$(utc_stamp).${ext}"
    fi
  fi

  echo "$REPORT" > "$FILE_TO_WRITE"
  log "Wrote report: $FILE_TO_WRITE"
else
  log "Not writing file (use --write to save a deliverable)."
fi
