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

variable "node_security_group_id" {
  type        = string
  description = "Security group ID used by Karpenter-managed worker nodes"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs available to Karpenter"
}

variable "node_group_role_name" {
  type        = string
  description = "IAM role name assigned to Karpenter-provisioned nodes"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "grafana_admin_password" {
  type    = string
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
