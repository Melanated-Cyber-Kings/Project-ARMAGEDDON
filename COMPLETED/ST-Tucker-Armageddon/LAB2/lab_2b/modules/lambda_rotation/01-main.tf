###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-2
# COMPONENT: general
# PURPOSE: Define infrastructure and automation logic for the LAB-2 track.
###############################################################################

# ============================================================
# Lab 1C — Rotation Lambda (Automated)
# Module: lambda_rotation
# Purpose: Deploy AWS-provided Secrets Manager RDS rotation Lambda
#          via Serverless Application Repository (SAR) into THIS account.
# ============================================================

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  sar_applications = {
    mysql    = "arn:aws:serverlessrepo:us-east-1:297356227824:applications/SecretsManagerRDSMySQLRotationSingleUser"
    postgres = "arn:aws:serverlessrepo:us-east-1:297356227824:applications/SecretsManagerRDSPostgreSQLRotationSingleUser"
  }

  application_id = local.sar_applications[var.engine]
}

resource "aws_serverlessapplicationrepository_cloudformation_stack" "lambda_rotation" {
  name           = var.stack_name
  application_id = local.application_id

  capabilities = [
    "CAPABILITY_IAM",
    "CAPABILITY_RESOURCE_POLICY",
    "CAPABILITY_AUTO_EXPAND"
  ]

  parameters = merge(
    {
      functionName = var.function_name
      endpoint     = var.endpoint
    },
    var.enable_vpc ? {
      vpcSubnetIds        = join(",", var.subnet_ids)
      vpcSecurityGroupIds = join(",", var.security_group_ids)
    } : {}
  )


  tags = var.tags
}
