output "aws_waf_web_acl_id" {
    value = aws_waf_web_acl.waf_acl.id
}

output "aws_waf_web_acl_arn" {
    value = aws_waf_web_acl.waf_acl.arn
}

output "aws_wafregional_web_acl_id" {
    value = aws_wafregional_web_acl.waf_acl.id
}

output "aws_wafregional_web_acl_arn" {
    value = aws_wafregional_web_acl.waf_acl.arn
}