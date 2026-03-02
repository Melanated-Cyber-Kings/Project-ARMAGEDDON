#!/usr/bin/env bash

# =====================================================
# TGW Connectivity Validator
# São Paulo (sa-east-1) <-> Tokyo (ap-northeast-1)
# =====================================================

set -e

TOKYO_REGION="ap-northeast-1"
SAO_REGION="sa-east-1"

TOKYO_TGW_NAME="shinjuku-tgw01"
SAO_TGW_NAME="liberdade-tgw01"

RDS_SG_NAME="armageddon-lab3-rds-sg"

echo "==============================================="
echo "Checking Transit Gateway Cross-Region Setup"
echo "Tokyo  Region: $TOKYO_REGION"
echo "São Paulo Region: $SAO_REGION"
echo "==============================================="

# --------------------------------------------
# Helper function
# --------------------------------------------
get_tgw_id() {
  aws ec2 describe-transit-gateways \
    --region "$1" \
    --filters "Name=tag:Name,Values=$2" \
    --query "TransitGateways[0].TransitGatewayId" \
    --output text
}

# --------------------------------------------
# Get TGW IDs
# --------------------------------------------
TOKYO_TGW_ID=$(get_tgw_id $TOKYO_REGION $TOKYO_TGW_NAME)
SAO_TGW_ID=$(get_tgw_id $SAO_REGION $SAO_TGW_NAME)

echo "Tokyo TGW: $TOKYO_TGW_ID"
echo "São TGW:   $SAO_TGW_ID"

if [[ "$TOKYO_TGW_ID" == "None" || "$SAO_TGW_ID" == "None" ]]; then
  echo "ERROR: Could not find one or both TGWs."
  exit 1
fi

# --------------------------------------------
# Check TGW Peering Status
# --------------------------------------------
echo ""
echo "Checking TGW Peering Attachment..."

PEERING_STATE=$(aws ec2 describe-transit-gateway-peering-attachments \
  --region $TOKYO_REGION \
  --filters "Name=transit-gateway-id,Values=$TOKYO_TGW_ID" \
  --query "TransitGatewayPeeringAttachments[0].State" \
  --output text)

echo "Peering State: $PEERING_STATE"

if [[ "$PEERING_STATE" != "available" ]]; then
  echo "ERROR: TGW peering not available."
  exit 1
fi

# --------------------------------------------
# Check VPC Attachments
# --------------------------------------------
echo ""
echo "Checking VPC Attachments..."

TOKYO_ATTACH=$(aws ec2 describe-transit-gateway-vpc-attachments \
  --region $TOKYO_REGION \
  --filters "Name=transit-gateway-id,Values=$TOKYO_TGW_ID" \
  --query "TransitGatewayVpcAttachments[0].State" \
  --output text)

SAO_ATTACH=$(aws ec2 describe-transit-gateway-vpc-attachments \
  --region $SAO_REGION \
  --filters "Name=transit-gateway-id,Values=$SAO_TGW_ID" \
  --query "TransitGatewayVpcAttachments[0].State" \
  --output text)

echo "Tokyo VPC Attachment: $TOKYO_ATTACH"
echo "São   VPC Attachment: $SAO_ATTACH"

if [[ "$TOKYO_ATTACH" != "available" || "$SAO_ATTACH" != "available" ]]; then
  echo "ERROR: One or more VPC attachments not available."
  exit 1
fi

# --------------------------------------------
# Check RDS Security Group rule
# --------------------------------------------
echo ""
echo "Checking RDS Security Group rule (3306 inbound)..."

RDS_SG_ID=$(aws ec2 describe-security-groups \
  --region $TOKYO_REGION \
  --filters "Name=tag:Name,Values=$RDS_SG_NAME" \
  --query "SecurityGroups[0].GroupId" \
  --output text)

if [[ "$RDS_SG_ID" == "None" ]]; then
  echo "ERROR: Could not find RDS Security Group."
  exit 1
fi

MYSQL_RULE=$(aws ec2 describe-security-groups \
  --region $TOKYO_REGION \
  --group-ids $RDS_SG_ID \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`3306\`]" \
  --output text)

if [[ -z "$MYSQL_RULE" ]]; then
  echo "ERROR: No MySQL 3306 rule found in RDS SG."
  exit 1
else
  echo "MySQL 3306 rule present."
fi

# --------------------------------------------
# Optional: DNS + TCP Check from São EC2
# --------------------------------------------
echo ""
echo "OPTIONAL: Testing TCP connectivity from São EC2 (SSM required)..."

SAO_INSTANCE=$(aws ec2 describe-instances \
  --region $SAO_REGION \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

if [[ "$SAO_INSTANCE" == "None" ]]; then
  echo "No running São Paulo EC2 found. Skipping TCP test."
else
  RDS_ENDPOINT=$(aws rds describe-db-instances \
    --region $TOKYO_REGION \
    --query "DBInstances[0].Endpoint.Address" \
    --output text)

  echo "Testing TCP 3306 to $RDS_ENDPOINT ..."

  aws ssm send-command \
    --region $SAO_REGION \
    --instance-ids "$SAO_INSTANCE" \
    --document-name "AWS-RunShellScript" \
    --parameters commands="nc -zv $RDS_ENDPOINT 3306" \
    --query "Command.CommandId" \
    --output text

  echo "SSM command sent. Check SSM Run Command for result."
fi

# --------------------------------------------
echo ""
echo "==============================================="
echo "RESULT: TGW Infrastructure Looks Healthy"
echo "If TCP test succeeds, cross-region routing works."
echo "==============================================="
