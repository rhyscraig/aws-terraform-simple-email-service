################################################
## SES Receipt Bucket
################################################

# Email receipt bucket
resource "aws_s3_bucket" "receipts" {
    bucket = "${var.account}-${var.domain_name}-ses-receipt-bucket"
    lifecycle {
        prevent_destroy = var.prevent_destroy
    }
}
resource "aws_s3_bucket_ownership_controls" "receipts" {
    bucket = aws_s3_bucket.receipts.id
    rule {
        object_ownership = "BucketOwnerPreferred"
    }
}


################################################
## SNS (For SES)
################################################

# Create SNS topic
resource "aws_sns_topic" "topic" {
  name = "fearfanatic"  # Replace with your desired topic name
}

# Create test topic subscription
resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = var.test_email_address
}

# Create SNS subscriptions for bounce, complaint and delivery
resource "aws_ses_identity_notification_topic" "test1" {
  topic_arn                = aws_sns_topic.topic.arn
  notification_type        = "Bounce"
  identity                 = aws_ses_domain_identity.example.domain
  include_original_headers = true
}
resource "aws_ses_identity_notification_topic" "test2" {
  topic_arn                = aws_sns_topic.topic.arn
  notification_type        = "Complaint"
  identity                 = aws_ses_domain_identity.example.domain
  include_original_headers = true
}
resource "aws_ses_identity_notification_topic" "test3" {
  topic_arn                = aws_sns_topic.topic.arn
  notification_type        = "Delivery"
  identity                 = aws_ses_domain_identity.example.domain
  include_original_headers = true
}

# Activity reporting (can go to CloudWatch too)
resource "aws_ses_event_destination" "sns" {
  name                   = "event-destination-sns"
  configuration_set_name = aws_ses_configuration_set.example.name
  enabled                = true
  matching_types         = ["bounce", "send"]

  sns_destination {
    topic_arn = aws_sns_topic.topic.arn
  }
}

#############################################
## Simple Email Service (SES) resources
#############################################

# Create email template
resource "aws_ses_template" "MyTemplate" {
  name    = "fearfanatic"
  subject = "Greetings, {{name}}!"
  html    = "<h1>Hello {{name}},</h1><p>Your favorite animal is {{favoriteanimal}}.</p>"
  text    = "Hello {{name}},\r\nYour favorite animal is {{favoriteanimal}}."
}

# Configuration Set
resource "aws_ses_configuration_set" "example" {
  name = "configuration-set-1"
}

// MAIN 
# create SES domain identity and verification
resource "aws_ses_domain_identity" "example" {
  domain = local.domain  # Replace with your actual domain
}
# Create Route53 record
resource "aws_route53_record" "example_amazonses_verification_record" {
  zone_id = data.aws_route53_zone.example.id
  name    = "_amazonses.${aws_ses_domain_identity.example.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.example.verification_token]
}
resource "aws_ses_domain_identity_verification" "example_verification" {
  domain = aws_ses_domain_identity.example.id
  depends_on = [aws_route53_record.example_amazonses_verification_record]
  timeouts {
    create = "10m"
  }
}
resource "aws_ses_domain_dkim" "example" {
  domain = aws_ses_domain_identity.example.domain
}
# Create Route53 Record
resource "aws_route53_record" "example_amazonses_dkim_record" {
  count   = 3
  zone_id = data.aws_route53_zone.example.id
  name    = "${aws_ses_domain_dkim.example.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_ses_domain_dkim.example.dkim_tokens[count.index]}.dkim.amazonses.com"]
}


# Domain Identity Policy Doc
data "aws_iam_policy_document" "example" {
  statement {
    actions   = ["SES:SendEmail", "SES:SendRawEmail"]
    resources = [aws_ses_domain_identity.example.arn]

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
  }
}
resource "aws_ses_identity_policy" "example" {
  identity = aws_ses_domain_identity.example.arn
  name     = "ses-identity-policy"
  policy   = data.aws_iam_policy_document.example.json
}


// MAIL FROM
resource "aws_ses_domain_mail_from" "example" {
  domain           = aws_ses_domain_identity.example.domain
  mail_from_domain = "info.${aws_ses_domain_identity.example.domain}"
}
# Example Route53 MX record
resource "aws_route53_record" "example_ses_domain_mail_from_mx" {
  zone_id = data.aws_route53_zone.example.id
  name    = aws_ses_domain_mail_from.example.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${var.region_name}.amazonses.com"] 
}

# Example Route53 TXT record for SPF
resource "aws_route53_record" "example_ses_domain_mail_from_txt" {
  zone_id = data.aws_route53_zone.example.id
  name    = aws_ses_domain_mail_from.example.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}


// TRUSTED EMAIL ADDRESSES
# Test SES Email identity
resource "aws_ses_email_identity" "hotmail" {
  email = "craighoad@hotmail.com"
}
# Test SES Email identity
resource "aws_ses_email_identity" "example" {
  email = "thefearfanatic@gmail.com"
}

// SES SMTP Credentials
# Create IAM user
resource "aws_iam_user" "user" {
  name = "${local.app}-ses-user"
  force_destroy = "true"
  tags = local.tags
}
# Create policy doc
data "aws_iam_policy_document" "policy_document" {
  statement {
    actions   = [      
      "ses:SendEmail",
      "ses:SendRawEmail",
      "ses:ReadEmail",
      "ses:ReadRawEmail",
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      "iam:GetAccessKeyLastUsed",
      "iam:ListAccessKeys",
      "iam:UpdateAccessKey"
    ]
    resources = [aws_ses_email_identity.example.arn]
  }
}
# Instanitate policy doc
resource "aws_iam_policy" "policy" {
  name   = "SES-send-policy"
  policy = data.aws_iam_policy_document.policy_document.json
}
# Attach policy doc to user
resource "aws_iam_user_policy_attachment" "user_policy" {
  user       = aws_iam_user.user.name
  policy_arn = aws_iam_policy.policy.arn
}
# Create SMTP access key
resource "aws_iam_access_key" "access_key" {
  user = aws_iam_user.user.name
}