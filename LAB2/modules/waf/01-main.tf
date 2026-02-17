terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_wafv2_web_acl" "this" {
  name  = "${var.name_prefix}-waf"
  scope = "CLOUDFRONT" 

  default_action {
    allow {}
  }


  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf-main"
    sampled_requests_enabled   = true
  }

  # ----------------------------------------------------------------------------
  # RULE 1: COMMON RULE SET 
  # ----------------------------------------------------------------------------
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRules"
      sampled_requests_enabled   = true
    }
  }

  # ----------------------------------------------------------------------------
  # RULE 2: IP RATE LIMITING (Automated Attack Mitigation)
  # ----------------------------------------------------------------------------
  rule {
    name     = "RateLimit-100"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 100 # Per 5-minute rolling window
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  # ----------------------------------------------------------------------------
  # RULE 3: SQL INJECTION PROTECTION (PHI Data Integrity)
  # ----------------------------------------------------------------------------
  rule {
    name     = "SQLiProtection"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLiRules"
      sampled_requests_enabled   = true
    }
  }

  # ----------------------------------------------------------------------------
  # RULE 4: KNOWN BAD INPUTS (Exploit Mitigation)
  # ----------------------------------------------------------------------------
  rule {
    name     = "KnownBadInputs"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BadInputs"
      sampled_requests_enabled   = true
    }
  }
}