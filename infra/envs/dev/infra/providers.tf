provider "aws" {
  region = "ap-south-1"
}

terraform {
  backend "s3" {
    bucket         = "amrendra-terraform-state"
    key            = "dev/infra/terraform.tfstate"
    region         = "ap-south-1"
    use_lockfile = true
    encrypt = true
  }
}