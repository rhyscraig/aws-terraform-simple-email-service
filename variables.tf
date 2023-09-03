variable domain_name {
    type = string
    description = "The name of the domain e.g. example"
    default = "example"
}

variable domain {
    type = string
    description = "The name of the domain e.g. example.com"
    default = "example.com"
}

variable default_tags {
    type = map(string)
    description = "Default tags to use for resources"
    default = {
        Deployment = "Terraform"
    }
}

variable create_s3_receipt_bucket {
    type = bool
    description = "Whether or not to create an S3 receipt bucket"
    default = "true"
}

variable create_sns_topic {
    type = bool
    description = "Whether or not to create an SNS topic"
    default = "true"
}

variable sns_test_email_address {
    type = string
    description = "Email address to use for testing SNS topic."
    default = ""
}

variable trusted_email_addresses {
    type = list(string)
    description = "A list of email addresses to whitelist"
    default = []
}

variable mail_from {
    type = string
    description = "The mail_from e.g. 'info' in 'info.example.com'"
    default = ""
}

variable region {
    type = string
    description = "The region in which to deploy SES"
}
