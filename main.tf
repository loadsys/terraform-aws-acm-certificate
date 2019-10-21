resource "aws_acm_certificate" "default" {
  provider                  = aws.acm_account
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"
  tags = merge(
    {
      "Name" = var.domain_name
    },
    var.tags,
  )
}

resource "aws_route53_record" "validation" {
  provider = aws.route53_account
  count    = length(var.subject_alternative_names) + 1

  name    = aws_acm_certificate.default.domain_validation_options[count.index]["resource_record_name"]
  type    = aws_acm_certificate.default.domain_validation_options[count.index]["resource_record_type"]
  zone_id = var.hosted_zone_id
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  records         = [aws_acm_certificate.default.domain_validation_options[count.index]["resource_record_value"]]
  ttl             = var.validation_record_ttl
  allow_overwrite = var.allow_validation_record_overwrite
}

resource "aws_acm_certificate_validation" "default" {
  provider        = aws.acm_account
  certificate_arn = aws_acm_certificate.default.arn

  validation_record_fqdns = aws_route53_record.validation.*.fqdn
}

