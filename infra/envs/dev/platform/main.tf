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
  cluster_endpoint  = data.terraform_remote_state.infra.outputs.cluster_endpoint
  cluster_ca        = data.terraform_remote_state.infra.outputs.cluster_ca
  oidc_provider_arn = data.terraform_remote_state.infra.outputs.oidc_provider_arn
  oidc_provider_url = data.terraform_remote_state.infra.outputs.oidc_provider_url
  region            = "ap-south-1"

  tags = {
    Environment = "dev"
    Owner       = "amrendra"
  }
}
