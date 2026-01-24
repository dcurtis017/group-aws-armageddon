variable "name_prefix" {
  type = string
}

variable "enable_waf" {
  type    = bool
  default = true
}

variable "enable_waf_logging" {
  type    = bool
  default = false
}

variable "associate_waf_with_resource_arn" {
  type = string
}

variable "waf_scope" {
  type    = string
  default = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.waf_scope)
    error_message = "Please use one of the following values: REGIONAL, CLOUDFRONT"
  }
}

variable "include_waf_acl_association" {
  type        = bool
  default     = true
  description = "The WAF association should not be used when the waf scope is CLOUDFRONT"
}
