data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_route53_zone" "example" {
  name         = "${var.domain}."
  private_zone = false
}

output "zone_id" {
  value = data.aws_route53_zone.example.id
}

output "region" {
  value = data.aws_region.current.name
}