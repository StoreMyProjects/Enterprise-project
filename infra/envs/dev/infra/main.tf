module "vpc" {
  source = "../../../modules/vpc"

  name = "devops"
  region = "ap-south-1"

  vpc_cidr = "10.0.0.0/16"

  azs = ["ap-south-1a", "ap-south-1b"]

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true

  tags = {
    Environment = "dev"
    Owner       = "amrendra"
  }
}

module "eks" {
  source = "../../../modules/eks"

  name = "devops-eks"
  region = "ap-south-1"

  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  endpoint_public_access = true

  public_access_cidrs = [
    "223.228.138.130/32"
  ]

  desired_capacity = 4
  max_capacity     = 5
  min_capacity     = 2

  tags = {
    Environment = "dev"
    Owner       = "amrendra"
  }
}