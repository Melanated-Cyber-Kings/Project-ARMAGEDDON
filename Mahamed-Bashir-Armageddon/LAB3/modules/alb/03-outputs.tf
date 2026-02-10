output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_arn" {
  value = aws_lb.this.arn
}

output "https_listener_arn" {
  # This matches the resource name in your 01-main.tf
  value = aws_lb_listener.https.arn 
}

output "target_group_arn" {
  # This matches the target group name in your 01-main.tf
  value = aws_lb_target_group.this.arn
}

output "alb_sg_id" {
  # Ensure the security module can find the ALB SG
  value = var.security_group_ids[0]
}