data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket = "amrendra-terraform-state"
    key    = "dev/infra/terraform.tfstate"
    region = "ap-south-1"
  }
}

module "addons" {
  source = "../../../modules/addons"

  cluster_name      = data.terraform_remote_state.infra.outputs.cluster_name
  oidc_provider_arn = data.terraform_remote_state.infra.outputs.oidc_provider_arn

}

module "helm" {
  source = "../../../modules/helm"

  cluster_name           = data.terraform_remote_state.infra.outputs.cluster_name
  cluster_endpoint       = data.terraform_remote_state.infra.outputs.cluster_endpoint
  cluster_ca             = data.terraform_remote_state.infra.outputs.cluster_ca
  oidc_provider_arn      = data.terraform_remote_state.infra.outputs.oidc_provider_arn
  oidc_provider_url      = data.terraform_remote_state.infra.outputs.oidc_provider_url
  node_security_group_id = data.terraform_remote_state.infra.outputs.node_security_group_id
  private_subnet_ids     = data.terraform_remote_state.infra.outputs.private_subnet_ids
  node_group_role_name   = "${data.terraform_remote_state.infra.outputs.cluster_name}-node-group-role"
  region                 = "ap-south-1"

  slack_warning_webhook_url  = "https://hooks.slack.com/services/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"
  slack_critical_webhook_url = "https://hooks.slack.com/services/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"

  tags = {
    Environment = "dev"
    Owner       = "amrendra"
  }
}