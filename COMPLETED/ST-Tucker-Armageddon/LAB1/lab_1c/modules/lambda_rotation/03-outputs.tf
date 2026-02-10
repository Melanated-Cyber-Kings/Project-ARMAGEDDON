###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: general
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

output "rotation_stack_id" {
  description = "CloudFormation stack ID of the SAR deployment."
  value       = aws_serverlessapplicationrepository_cloudformation_stack.lambda_rotation.id
}

output "rotation_region" {
  description = "Region where the rotation Lambda is deployed."
  value       = data.aws_region.current.id
}

output "rotation_account_id" {
  description = "AWS account ID that owns the rotation Lambda."
  value       = data.aws_caller_identity.current.account_id
}

output "rotation_lambda_name" {
  description = "Rotation Lambda function name (requested)."
  value       = var.function_name
}

output "rotation_sar_application" {
  value = local.sar_applications[var.engine]
}

# Best-effort: get the real Lambda ARN from the SAR stack outputs.
# Output key names vary across AWS rotation templates, so we try common ones.
# output "rotation_lambda_arn" {
#   description = "Rotation Lambda ARN (from SAR outputs if available; otherwise constructed)."
#   value = coalesce(
#     try(aws_serverlessapplicationrepository_cloudformation_stack.lambda_rotation.outputs["RotationLambdaArn"], null),
#     try(aws_serverlessapplicationrepository_cloudformation_stack.lambda_rotation.outputs["RotationLambdaARN"], null),
#     try(aws_serverlessapplicationrepository_cloudformation_stack.lambda_rotation.outputs["LambdaFunctionArn"], null),
#     try(aws_serverlessapplicationrepository_cloudformation_stack.lambda_rotation.outputs["LambdaArn"], null),
#     try(aws_serverlessapplicationrepository_cloudformation_stack.lambda_rotation.outputs["LambdaARN"], null),
#     "arn:aws:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${var.function_name}"
#   )
# }

output "rotation_lambda_arn" {
  description = "ARN of the deployed rotation Lambda function."
  value       = "arn:aws:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${var.function_name}"
}
