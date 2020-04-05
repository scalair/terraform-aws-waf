variable "rate_limit_rules" {
    type = list(any)
}

variable "acl_name" {
    type = string
}

variable "acl_metric_name" {
    type = string
}

variable "acl_action_type" {
    type    = string
    default = "COUNT"
}