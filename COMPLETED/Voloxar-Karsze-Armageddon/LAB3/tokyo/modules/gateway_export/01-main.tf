resource "aws_ssm_parameter" "peer_tgw_id" {
  name        = "/lab/gateway/peer_tgw_id"
  type        = "String"
  value       = var.peer_tgw_id
  description = "peer transit gateway id"

}

resource "aws_ssm_parameter" "tgw_attach_id" {
  name        = "/lab/gateway/tgw_attach_id"
  type        = "String"
  value       = var.tgw_attach_id
  description = "attached transit gateway id"

}


resource "aws_ssm_parameter" "sao_vpc_id" {
  name        = "/lab/gateway/sao_vpc_id"
  type        = "String"
  value       = var.tgw_attach_id
  description = "san paulo vpc id"

}