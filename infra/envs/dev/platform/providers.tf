provider "aws" {
  region = "ap-south-1"
}

terraform {
  backend "s3" {
    bucket         = "amrendra-terraform-state"
    key            = "dev/platform/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock"
  }
}