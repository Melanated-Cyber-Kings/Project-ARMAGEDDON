output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_id" {
  value = module.network.public_subnet_id
}

output "db_endpoint" {
  value = module.database.db_endpoint
}

output "db_name" {
  value = module.database.db_name
}

output "ec2_public_ip" {
  value = module.compute.public_ip
}

output "cloudwatch_log_group" {
  value = module.monitoring.log_group_name
}

output "cloudwatch_alarm_name" {
  value = module.monitoring.alarm_name
}

output "monitoring_sns_topic_arn" {
  value = module.monitoring.sns_topic_arn
}

output "incident_response_lambda_name" {
  value = module.incident_response.lambda_function_name
}

output "ssm_parameters" {
  value = {
    endpoint = "/lab1b/db/endpoint"
    port     = "/lab1b/db/port"
    name     = "/lab1b/db/name"
  }
}

output "secrets_manager_secret" {
  value = "lab1b/rds/mysql"
}

output "verification_commands" {
  value = <<-EOT
    # Verification Commands:
    1. Check SSM: aws ssm get-parameters --names /lab1b/db/endpoint /lab1b/db/port /lab1b/db/name --with-decryption
    2. Check Secrets: aws secretsmanager get-secret-value --secret-id lab1b/rds/mysql
    3. Check Logs: aws logs describe-log-groups --log-group-name-prefix /aws/ec2/lab1b
    4. Check Alarm: aws cloudwatch describe-alarms --alarm-name-prefix lab1b
    5. Test App: curl http://${module.compute.public_ip}:8080/health
    6. Test DB: curl http://${module.compute.public_ip}:8080/list
    7. Check Lambda: aws lambda get-function --function-name ${module.incident_response.lambda_function_name}
  EOT
}