#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Bonus A Validation Script — EC2 Web App → RDS (MySQL) Notes App
#
# Source: "EC2 Web App → RDS (MySQL) Notes App" developer notes (provided)
#
# Run from: envs/lab-1c
# Output:   ../../deliverables/bonus_a_cli_verification.md
#
# What this script verifies (CLI evidence):
# - SG inventory + inspection (EC2 SG + RDS SG)
# - Which resources are using a given SG (EC2 and RDS)
# - RDS sanity checks: publicly accessible flag, subnet group, SGs
# - Secrets Manager: list secrets + describe secret (metadata only)
# - IAM role attached to EC2 + policies
# - Optional app endpoint smoke tests (/init, /add, /list) if ALB/EIP is known
###############################################################################

REGION_DEFAULT="ap-northeast-1"
OUTFILE_DEFAULT="../../deliverables/bonus_a_cli_verification.md"

# Your lab secret name: update if different.
# Dev notes example used "lab/rds/mysql"; your lab often uses "lab-1c/rds/mysql".
SECRET_NAME_DEFAULT="lab-1c/rds/mysql"

# Optional: tag Name values used for discovery if terraform outputs aren't present
EC2_NAME_TAG_DEFAULT="lab-ec2-app"
RDS_IDENTIFIER_DEFAULT="lab-mysql"

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/bonus_a_validate.sh [--region <region>] [--outfile <path>] [--secret-name <name>] [--ec2-name-tag <tag>] [--rds-id <id>]

Examples:
  ./scripts/bonus_a_validate.sh
  ./scripts/bonus_a_validate.sh --region ap-northeast-1 --secret-name lab-1c/rds/mysql
USAGE
}

REGION="$REGION_DEFAULT"
OUTFILE="$OUTFILE_DEFAULT"
SECRET_NAME="$SECRET_NAME_DEFAULT"
EC2_NAME_TAG="$EC2_NAME_TAG_DEFAULT"
RDS_ID="$RDS_IDENTIFIER_DEFAULT"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region) REGION="$2"; shift 2 ;;
    --outfile) OUTFILE="$2"; shift 2 ;;
    --secret-name) SECRET_NAME="$2"; shift 2 ;;
    --ec2-name-tag) EC2_NAME_TAG="$2"; shift 2 ;;
    --rds-id) RDS_ID="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing command: $1"; exit 1; }; }
need_cmd terraform
need_cmd aws
need_cmd sed
need_cmd awk
need_cmd date
need_cmd mkdir

if [[ ! -f "./01-main.tf" ]]; then
  echo "ERROR: run this script from envs/lab-1c"
  exit 1
fi

mkdir -p "$(dirname "$OUTFILE")"

ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
md() { printf "%s\n" "$*" >> "$OUTFILE"; }

run() {
  # run <title> <command...>
  local title="$1"; shift
  md ""
  md "### ${title}"
  md ""
  md '```bash'
  md "$*"
  md '```'
  md ""
  md '```text'
  set +e
  "$@" 2>&1 | sed 's/\r$//' >> "$OUTFILE"
  local rc=$?
  set -e
  md '```'
  md ""
  return $rc
}

tf_out() {
  # terraform output -raw might fail if output doesn't exist
  terraform output -raw "$1" 2>/dev/null || true
}

###############################################################################
# Resolve key IDs (prefer terraform outputs, fallback to discovery)
###############################################################################

# Try to get instance id from TF output if present
EC2_INSTANCE_ID="$(tf_out ec2_instance_id)"
EC2_PUBLIC_IP="$(tf_out ec2_public_ip)"
EC2_PUBLIC_DNS="$(tf_out ec2_public_dns)"

# Try to get SG IDs from TF outputs if present
EC2_SG_ID="$(tf_out ec2_sg_id)"
RDS_SG_ID="$(tf_out rds_sg_id)"

# Try to get RDS identifier/endpoint from TF outputs if present
RDS_INSTANCE_ID="$(tf_out rds_instance_identifier)"
RDS_ENDPOINT="$(tf_out rds_endpoint)"

# Fallback discovery if missing
if [[ -z "$EC2_INSTANCE_ID" ]]; then
  EC2_INSTANCE_ID="$(aws ec2 describe-instances --region "$REGION" \
    --filters "Name=tag:Name,Values=${EC2_NAME_TAG}" "Name=instance-state-name,Values=running,stopped,pending" \
    --query "Reservations[].Instances[].InstanceId" --output text 2>/dev/null || true)"
fi

if [[ -z "$RDS_INSTANCE_ID" ]]; then
  RDS_INSTANCE_ID="$RDS_ID"
fi

###############################################################################
# Write report header
###############################################################################
: > "$OUTFILE"
md "# Bonus A CLI Verification — EC2 Notes App → RDS MySQL"
md ""
md "- Generated (UTC): \`$(ts)\`"
md "- Region: \`$REGION\`"
md "- Secret name: \`$SECRET_NAME\`"
md "- EC2 Name tag lookup: \`$EC2_NAME_TAG\`"
md "- RDS identifier: \`$RDS_INSTANCE_ID\`"
md ""
md "## Resolved IDs (best effort)"
md ""
md "- EC2 InstanceId: \`${EC2_INSTANCE_ID:-NOT_FOUND}\`"
md "- EC2 SG: \`${EC2_SG_ID:-NOT_FOUND}\`"
md "- RDS SG: \`${RDS_SG_ID:-NOT_FOUND}\`"
md "- RDS Endpoint (TF output): \`${RDS_ENDPOINT:-NOT_FOUND}\`"
md ""

###############################################################################
# Section: AWS CLI checks (mirrors developer notes)
###############################################################################

md "## Part 1 — Security Groups (inventory + inspection)"
md ""

run "List all security groups (region inventory)" aws ec2 describe-security-groups \
  --region "$REGION" \
  --query "SecurityGroups[].{GroupId:GroupId,Name:GroupName,VpcId:VpcId}" \
  --output table

if [[ -n "$EC2_SG_ID" ]]; then
  run "Inspect EC2 security group (inbound/outbound) — $EC2_SG_ID" aws ec2 describe-security-groups \
    --group-ids "$EC2_SG_ID" \
    --region "$REGION" \
    --output json
fi

if [[ -n "$RDS_SG_ID" ]]; then
  run "Inspect RDS security group (inbound/outbound) — $RDS_SG_ID" aws ec2 describe-security-groups \
    --group-ids "$RDS_SG_ID" \
    --region "$REGION" \
    --output json
fi

md "## Part 1 — Verify which resources use a given SG"
md ""

if [[ -n "$EC2_SG_ID" ]]; then
  run "EC2 instances using EC2 SG — $EC2_SG_ID" aws ec2 describe-instances \
    --filters "Name=instance.group-id,Values=$EC2_SG_ID" \
    --region "$REGION" \
    --query "Reservations[].Instances[].InstanceId" \
    --output table
fi

if [[ -n "$RDS_SG_ID" ]]; then
  run "RDS instances using RDS SG — $RDS_SG_ID" aws rds describe-db-instances \
    --region "$REGION" \
    --query "DBInstances[?contains(VpcSecurityGroups[].VpcSecurityGroupId, '$RDS_SG_ID')].DBInstanceIdentifier" \
    --output table
fi

md "## Part 1 — RDS instance checks (public flag, SGs, subnet group)"
md ""

run "List all RDS instances (inventory)" aws rds describe-db-instances \
  --region "$REGION" \
  --query "DBInstances[].{DB:DBInstanceIdentifier,Engine:Engine,Public:PubliclyAccessible,Vpc:DBSubnetGroup.VpcId}" \
  --output table

run "Inspect specific RDS instance (json) — $RDS_INSTANCE_ID" aws rds describe-db-instances \
  --db-instance-identifier "$RDS_INSTANCE_ID" \
  --region "$REGION" \
  --output json

run "RDS SG IDs (table) — $RDS_INSTANCE_ID" aws rds describe-db-instances \
  --db-instance-identifier "$RDS_INSTANCE_ID" \
  --region "$REGION" \
  --query "DBInstances[].VpcSecurityGroups[].VpcSecurityGroupId" \
  --output table

run "RDS subnet groups (placement)" aws rds describe-db-subnet-groups \
  --region "$REGION" \
  --query "DBSubnetGroups[].{Name:DBSubnetGroupName,Vpc:VpcId,Subnets:Subnets[].SubnetIdentifier}" \
  --output table

run "RDS PubliclyAccessible quick flag (expected: false)" aws rds describe-db-instances \
  --db-instance-identifier "$RDS_INSTANCE_ID" \
  --region "$REGION" \
  --query "DBInstances[].PubliclyAccessible" \
  --output text

md "## Part 3 — Secrets Manager checks (metadata only)"
md ""

run "List secrets (name/arn/rotation)" aws secretsmanager list-secrets \
  --region "$REGION" \
  --query "SecretList[].{Name:Name,ARN:ARN,Rotation:RotationEnabled}" \
  --output table

run "Describe secret (NO value exposure) — $SECRET_NAME" aws secretsmanager describe-secret \
  --secret-id "$SECRET_NAME" \
  --region "$REGION" \
  --output json

md "## Part 3 — IAM role attached to EC2 + policy checks"
md ""

if [[ -n "$EC2_INSTANCE_ID" ]]; then
  run "EC2 instance IAM instance profile ARN (empty = finding) — $EC2_INSTANCE_ID" aws ec2 describe-instances \
    --instance-ids "$EC2_INSTANCE_ID" \
    --region "$REGION" \
    --query "Reservations[].Instances[].IamInstanceProfile.Arn" \
    --output text

  # Resolve instance-profile name from the ARN, then role name.
  PROFILE_ARN="$(aws ec2 describe-instances --instance-ids "$EC2_INSTANCE_ID" --region "$REGION" \
    --query "Reservations[].Instances[].IamInstanceProfile.Arn" --output text 2>/dev/null || true)"

  if [[ -n "$PROFILE_ARN" && "$PROFILE_ARN" != "None" ]]; then
    PROFILE_NAME="$(echo "$PROFILE_ARN" | awk -F'/' '{print $NF}')"

    run "Resolve instance profile → role name — $PROFILE_NAME" aws iam get-instance-profile \
      --instance-profile-name "$PROFILE_NAME" \
      --query "InstanceProfile.Roles[].RoleName" \
      --output text

    ROLE_NAME="$(aws iam get-instance-profile --instance-profile-name "$PROFILE_NAME" \
      --query "InstanceProfile.Roles[].RoleName" --output text 2>/dev/null || true)"

    if [[ -n "$ROLE_NAME" && "$ROLE_NAME" != "None" ]]; then
      run "List attached managed policies — $ROLE_NAME" aws iam list-attached-role-policies \
        --role-name "$ROLE_NAME" \
        --output table

      run "List inline policies — $ROLE_NAME" aws iam list-role-policies \
        --role-name "$ROLE_NAME" \
        --output table
    fi
  fi
fi

md "## Part 5 — App smoke test (optional)"
md ""
md "> If EC2 has a public IP/DNS and the app is bound to port 80, these endpoints should work:"
md "> - /init"
md "> - /add?note=first_note"
md "> - /list"
md ""
md "> This script does not curl by default to avoid false negatives if inbound 80 is intentionally restricted."
md ""

md "## Recommended Evidence Exports (audit-friendly)"
md ""
md "> If you need raw json artifacts, run these and attach outputs to deliverables:"
md ""
md '```bash'
md "# Example SG export (update SG id):"
md "aws ec2 describe-security-groups --group-ids <sg-id> --region ${REGION} > sg.json"
md ""
md "# Example RDS export:"
md "aws rds describe-db-instances --db-instance-identifier ${RDS_INSTANCE_ID} --region ${REGION} > rds.json"
md ""
md "# Example Secret export (metadata only):"
md "aws secretsmanager describe-secret --secret-id ${SECRET_NAME} --region ${REGION} > secret.json"
md ""
md "# Example EC2 export:"
md "aws ec2 describe-instances --instance-ids ${EC2_INSTANCE_ID:-<instance-id>} --region ${REGION} > instance.json"
md ""
md "# Example role policies:"
md "aws iam list-attached-role-policies --role-name <role-name> > role-policies.json"
md "aws iam list-role-policies --role-name <role-name> > role-inline-policies.json"
md '```'
md ""

md "---"
md "✅ Script completed at \`$(ts)\`"
echo "Wrote verification report: $OUTFILE"
