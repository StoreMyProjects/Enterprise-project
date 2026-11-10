variable "cluster_name" {
  type = string
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

variable "node_security_group_id" {
  type        = string
  description = "Security group used by EKS worker nodes and application pods"
}