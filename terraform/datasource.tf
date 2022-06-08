# get zone for the hosted zone

data "aws_route53_zone" "zone" {
  name         = "tickler.in"
  private_zone = false
}
