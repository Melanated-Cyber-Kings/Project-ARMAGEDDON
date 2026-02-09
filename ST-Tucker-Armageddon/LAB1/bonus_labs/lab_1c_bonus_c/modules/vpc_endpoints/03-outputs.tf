###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: VPC Endpoints Outputs
# PURPOSE: Define infrastructure and automation logic for the LAB-1 track.
###############################################################################

output "interface_endpoint_service_names" {
  description = "Service names for created interface endpoints"
  value       = [for k, v in aws_vpc_endpoint.interface : v.service_name]
}

output "s3_gateway_endpoint_service_name" {
  description = "Service name for the S3 gateway endpoint"
  value       = aws_vpc_endpoint.s3_gateway.service_name
}
