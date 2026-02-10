resource "aws_route53_zone" "main" {
  #name = "lewsdomain.com" # <-- your actual domain here 
  name = "devlab405.click" # public hosted zone
}




########################################################################

resource "aws_route53_record" "shinjuku_origin" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "shinjuku-origin.devlab405.click"
  type    = "A"

  alias {
    name                   = aws_lb.shinjuku_alb.dns_name
    zone_id                = aws_lb.shinjuku_alb.zone_id
    evaluate_target_health = false
  }
}


#########################################################################

resource "aws_route53_record" "liberdade_origin" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "liberdade-origin.devlab405.click"
  type    = "A"

  alias {
    name                   = aws_lb.liberdade_alb.dns_name
    zone_id                = aws_lb.liberdade_alb.zone_id
    evaluate_target_health = false
  }
}