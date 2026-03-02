output "alert_email" {
  value = aws_sns_topic_subscription.email.endpoint
}