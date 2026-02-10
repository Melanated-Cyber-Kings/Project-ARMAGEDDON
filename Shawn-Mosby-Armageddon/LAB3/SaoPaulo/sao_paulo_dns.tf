
resource "aws_route53_record" "liberdade_origin" {
  zone_id = data.terraform_remote_state.tokyo.outputs.route53_zone_id
  name    = "liberdade-origin.lewsdomain.com"
  type    = "A"

  alias {
    name                   = aws_lb.liberdade_alb.dns_name
    zone_id                = aws_lb.liberdade_alb.zone_id
    evaluate_target_health = false
  }
}