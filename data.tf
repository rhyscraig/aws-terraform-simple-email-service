data "aws_caller_identity" "current" {}
data "aws_route53_zone" "example" {}
data "aws_region" "current" {}

output "zone_id" {
  value = data.aws_route53_zone.example.id
}

output "region" {
  value = data.aws_region.current.name
}