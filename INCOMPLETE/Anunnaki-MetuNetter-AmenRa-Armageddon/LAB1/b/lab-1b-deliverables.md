To upgrade your Terraform code from Lab-1a to Lab-1b, you need to activate the commented-out sections of your code and bridge the gap between your infrastructure and the application layer.
Here is the breakdown of what you need to change and why to satisfy the 2026 Lab Requirements.
1. Externalize Database Configuration (Requirement A)
In Lab-1a, your EC2 likely used hardcoded variables. For Lab-1b, you must use Parameter Store.
What to do: Uncomment your aws_ssm_parameter resources for endpoint, port, and name.
Why: This allows the EC2 to query the database location dynamically. It satisfies Technical Verification 7.1.
Action: Ensure the name attributes match the requirements exactly: /lab/db/endpoint, /lab/db/port, and /lab/db/name.
2. Secure Credential Management (Requirement A)
The lab requires credentials to be moved out of Terraform variables and into Secrets Manager.
What to do: Ensure your aws_secretsmanager_secret resource name is set to lab/rds/mysql.
Why: This satisfies Technical Verification 7.2. It allows you to update a password in the AWS Console and have the EC2 pick it up without a code change.
3. Grant EC2 "Permission to Speak" (Requirement 7.3)
Your current ec2_role01 only has permission for CloudWatch logs. It cannot read the secrets yet.
What to do: Add an aws_iam_role_policy (inline policy) to your ec2_role01.
Why: Without this, your EC2 will receive an AccessDeniedException when it tries to run the CLI commands in Requirement 7.3.
Required Permissions:
ssm:GetParameter
secretsmanager:GetSecretValue
4. Create the "Log-to-Alarm" Bridge (Requirement B)
You have a Log Group and an Alarm, but they aren't connected yet.
What to do: Add an aws_cloudwatch_log_metric_filter resource.
Why: This is the "brain" that scans your logs for the word "ERROR". When it finds one, it increments the DBConnectionErrors metric, which then triggers your aws_cloudwatch_metric_alarm.
Required Pattern: The filter pattern must be "ERROR" to satisfy Technical Verification 7.5.
5. Transition to Dynamic User Data (Requirement C)
This is the most important step for the Incident Response Proof.
What to do: Update your user_data.sh file to perform a "Lookup" instead of using hardcoded strings.
The Logic:
The script runs aws ssm get-parameter to find where the DB is.
The script runs aws secretsmanager get-secret-value to get the password.
The script starts the application.
Why: This enables Requirement 7.7 (Recovery). To fix a "Credential Failure," you simply update Secrets Manager and restart the app service on the EC2. No terraform apply or EC2 replacement is needed.
Summary of Resource Status
Lab-1a Status	Resource Type	Requirement for Lab-1b
Commented Out	aws_ssm_parameter	Uncomment and set names to /lab/db/...
Present	aws_secretsmanager_secret	Rename to lab/rds/mysql
Missing	aws_iam_role_policy	Add to give EC2 access to SSM/Secrets
Missing	aws_cloudwatch_log_metric_filter	Add to detect "ERROR" in logs
Static	user_data.sh	Rewrite to use AWS CLI lookups
By implementing these changes, you move from a "Hardcoded Base" to a "Resilient Cloud Architecture" that can be verified entirely via the AWS CLI as requested in Section 7.



To make your CloudWatch Alarm work for Lab-1b, you are missing the "bridge" known as a Metric Filter. This resource scans your application logs for the word ERROR and turns those text entries into a numeric metric that the Alarm can actually watch.
Add this code to your monitoring.tf file:
hcl
############################################
# 1. Log Group (Ensure name matches Lab Requirements)
############################################
resource "aws_cloudwatch_log_group" "log_group01" {
  name              = "/aws/ec2/lab-rds-app" # Exact name for CLI verification 7.4
  retention_in_days = 7
}

############################################
# 2. Metric Filter (The "Bridge")
############################################
# This scans logs for "ERROR" and increments a counter.
resource "aws_cloudwatch_log_metric_filter" "db_error_filter" {
  name           = "DBConnectionErrorFilter"
  pattern        = "\"ERROR\"" # Looks for the literal string ERROR
  log_group_name = aws_cloudwatch_log_group.log_group01.name

  metric_transformation {
    name      = "DBConnectionErrors" # Must match the Alarm metric_name below
    namespace = "Lab/RDSApp"         # Must match the Alarm namespace below
    value     = "1"                  # Increment the count by 1 for every match
  }
}

############################################
# 3. CloudWatch Alarm
############################################
resource "aws_cloudwatch_metric_alarm" "db_alarm01" {
  alarm_name          = "lab-db-connection-failure" # Exact name for CLI verification 7.6
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DBConnectionErrors"
  namespace           = "Lab/RDSApp"
  period              = "60" # Check every minute for faster lab verification
  statistic           = "Sum"
  threshold           = "1" # Trigger alarm on the very first error

  alarm_description   = "This alarm monitors rds connection failures in app logs"
  alarm_actions       = [aws_sns_topic.sns_topic01.arn]
  
  # Ensures the alarm resets when errors stop
  treat_missing_data  = "notBreaching" 
}
Use code with caution.

Why this code works for 2026 Lab Standards:
Metric Filter Integration: Your previous code had an Alarm but no way to feed it data. This aws_cloudwatch_log_metric_filter creates the DBConnectionErrors metric in the Lab/RDSApp namespace dynamically as your EC2 sends logs.
CLI Verification (7.4 & 7.6): The names used here (/aws/ec2/lab-rds-app and lab-db-connection-failure) match the exact strings the lab's technical verification commands are looking for.
Low Threshold: I set the threshold to 1 and the period to 60. This ensures that as soon as you simulate a failure (Step 7.5), the alarm triggers quickly so you don't have to wait 5 minutes for your "Incident Response Proof."
Important Reminder for EC2:
For this alarm to trigger, your application on the EC2 must write to the log file that the CloudWatch Agent is shipping. If your app doesn't print the word ERROR to the log, the filter will never see it, and the alarm will stay OK.