variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}


variable "tags" {
  type    = map(string)
  default = {}
}

variable "region" {
  type = string
}

variable "enable_nat_gateway" {
  default = true
}

variable "enable_flow_logs" {
  default = true
}