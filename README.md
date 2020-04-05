# Terraform AWS WAF

This module creates WEB ACL for AWS WAF v1 and allows to associate an ALB to a regional Web ACL.

For now it only supports rate-based rules with URLs matching.

# Usage example

```
module "webacl" {
  source  = "github.com/scalair/terraform-aws-waf"

  acl_name = "test_rule"
  acl_metric_name = "TestRule"
  acl_action_type = "BLOCK"
  
  rate_limit_rules = [
    {
      url   = "/oauth/v2/token",
      type = "global",
      limit = 100,
    },
    {
      url   = "/api/users/reset_password",
      type = "regional",
      limit = 200,
      alb_arn = dependency.alb.outputs.load_balancer_id
    }
  ]
}
```

> Notes:
> - A rule can either be `global` or `regional`. If it is `regional`, it can be associated with an ALB.
> - AWS rate limit rules are evaluated for a 5 minute period.