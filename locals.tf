locals {
    account_id = data.aws_caller_identity.current.account_id
    zone_id = data.aws_route53_zone.example.id
    region = data.aws_region.current.name
}