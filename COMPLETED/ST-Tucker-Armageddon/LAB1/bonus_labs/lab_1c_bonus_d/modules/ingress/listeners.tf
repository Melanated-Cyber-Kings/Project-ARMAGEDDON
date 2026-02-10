###############################################################################
# listeners.tf
# Module: ingress (Lab-1C Bonus D)
###############################################################################

resource "aws_lb_listener" "http_80" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# resource "aws_lb_listener" "https_443" {
#   count             = local.enable_https_listener ? 1 : 0
#   load_balancer_arn = aws_lb.app_alb.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

#   certificate_arn = aws_acm_certificate.app_cert.arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app_tg.arn
#   }

#   # depends_on must be static. We enforce ordering by referencing the validation resource when it exists.
#   # In Route53 modes, app_cert_validation has count=1 -> index [0] exists.
#   depends_on = [
#     aws_route53_record.acm_validation,
#     aws_acm_certificate_validation.app_cert_validation
#   ]
# }

resource "aws_lb_listener" "https_443" {
  count             = local.enable_https_listener ? 1 : 0
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  certificate_arn = aws_acm_certificate.app_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
