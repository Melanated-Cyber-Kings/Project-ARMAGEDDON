output "vpc_id" {
  value = aws_vpc.chewbacca_vpc01.id
}

output "vpc_cidr" {
  value = aws_vpc.chewbacca_vpc01.cidr_block
}

output "rds_endpoint" {
  description = "The endpoint of the Tokyo RDS for the doctors in Brazil to hit"
  value       = aws_db_instance.shinjuku_medical_db.address
}

output "tgw_id" {
  description = "The ID of the Tokyo Transit Gateway (Hub)"
  value       = aws_ec2_transit_gateway.shinjuku_tgw01.id
}

output "rds_sg_id" {
  description = "The Security Group of the RDS to allow São Paulo ingress"
  value       = aws_security_group.chewbacca_rds_sg01.id
}

output "route53_zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "ssm_profile_name" {
  description = "The name of the IAM instance profile for SSM access"
  value       = aws_iam_instance_profile.ssm_profile.name
}