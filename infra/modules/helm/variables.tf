variable "cluster_name" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "cluster_ca" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "grafana_admin_password" {
  type = string
  default = "admin123"
}

variable "slack_warning_webhook_url" {
  type      = string
  sensitive = true
}

variable "slack_critical_webhook_url" {
  type      = string
  sensitive = true
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "cluster_security_group_id" {
  type = string
}