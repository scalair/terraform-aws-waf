locals {
  global_urls = flatten([
    for rule in var.rate_limit_rules : [{
      name  = replace(lookup(rule, "url", ""), "/[^a-zA-Z0-9]/", "")
      url   = lookup(rule, "url", "")
      limit = lookup(rule, "limit", "")
    }] if lookup(rule, "type", "") == "global"
  ])
}

resource "aws_waf_byte_match_set" "url_matches" {
  for_each = { for url in local.global_urls : url.name => url.url }

  name = format("url_match_%s", each.key)

  byte_match_tuples {
    text_transformation   = "COMPRESS_WHITE_SPACE"
    positional_constraint = "STARTS_WITH"
    target_string         = each.value

    field_to_match {
      type = "URI"
    }
  }
}

resource "aws_waf_rate_based_rule" "rate_based_rules" {
  for_each = { for url in local.global_urls : url.name => url.limit }

  name        = format("rate_based_rule_%s_%d", each.key, each.value)
  metric_name = format("RateBasedRule%s%d", each.key, each.value)

  rate_key   = "IP"
  rate_limit = each.value

  predicates {
    data_id = aws_waf_byte_match_set.url_matches[each.key].id
    negated = false
    type    = "ByteMatch"
  }
}

resource "aws_waf_web_acl" "waf_acl" {
  name        = var.acl_name
  metric_name = var.acl_metric_name

  default_action {
    type = "ALLOW"
  }

  dynamic "rules" {
    for_each = values(aws_waf_rate_based_rule.rate_based_rules)
    content {
      action {
        type = var.acl_action_type
      }
      priority = 1 + rules.key
      rule_id  = rules.value.id
      type     = "RATE_BASED"
    }
  }
}

locals {
  regional_urls = flatten([
    for rule in var.rate_limit_rules : [{
      name  = replace(lookup(rule, "url", ""), "/[^a-zA-Z0-9]/", "")
      url   = lookup(rule, "url", "")
      limit = lookup(rule, "limit", "")
      alb_arn = lookup(rule, "alb_arn", "")
    }] if lookup(rule, "type", "") == "regional"
  ])
}

resource "aws_wafregional_byte_match_set" "url_matches" {
  for_each = { for url in local.regional_urls : url.name => url.url }

  name = format("url_match_%s", each.key)

  byte_match_tuples {
    text_transformation   = "COMPRESS_WHITE_SPACE"
    positional_constraint = "STARTS_WITH"
    target_string         = each.value

    field_to_match {
      type = "URI"
    }
  }
}

resource "aws_wafregional_rate_based_rule" "rate_based_rules" {
  for_each = { for url in local.regional_urls : url.name => url.limit }

  name        = format("rate_based_rule_%s_%d", each.key, each.value)
  metric_name = format("RateBasedRule%s%d", each.key, each.value)

  rate_key   = "IP"
  rate_limit = each.value

  predicate {
    data_id = aws_wafregional_byte_match_set.url_matches[each.key].id
    negated = false
    type    = "ByteMatch"
  }
}

resource "aws_wafregional_web_acl" "waf_acl" {
  name        = var.acl_name
  metric_name = var.acl_metric_name

  default_action {
    type = "ALLOW"
  }

  dynamic "rule" {
    for_each = values(aws_wafregional_rate_based_rule.rate_based_rules)
    content {
      action {
        type = var.acl_action_type
      }
      priority = 1 + rule.key
      rule_id  = rule.value.id
      type     = "RATE_BASED"
    }
  }
}

resource "aws_wafregional_web_acl_association" "alb_association" {
  for_each = { for url in local.regional_urls : url.name => url.alb_arn }

  web_acl_id   = aws_wafregional_web_acl.waf_acl.id
  resource_arn = each.value
}