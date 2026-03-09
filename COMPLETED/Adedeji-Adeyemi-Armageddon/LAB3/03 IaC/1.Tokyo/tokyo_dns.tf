resource "aws_route53_zone" "main" {
  #change mod
  #name         = "lewsdomain.com"  # <-- your actual domain here 
  name         = "tritechsite.com"                    # public hosted zone
}




########################################################################

resource "aws_route53_record" "shinjuku_origin" {
  zone_id = aws_route53_zone.main.zone_id
  #change mod
  #name    = "shinjuku-origin.lewsdomain.com"
  name    = "shinjuku-origin.tritechsite.com"
  type    = "A"

  alias {
    name                   = aws_lb.shinjuku_alb.dns_name
    zone_id                = aws_lb.shinjuku_alb.zone_id
    evaluate_target_health = false
  }
}


#########################################################################
