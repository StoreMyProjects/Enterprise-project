module "vpc" {
  source = "../../modules/vpc"

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
  source = "../../modules/eks"

  name = "devops-eks"
  region = "ap-south-1"

  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  desired_capacity = 2
  max_capacity     = 3
  min_capacity     = 1

  tags = {
    Environment = "dev"
    Owner       = "amrendra"
  }
}

module "addons" {
  source = "../../modules/addons"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_ca        = module.eks.cluster_ca
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  region            = "ap-south-1"

  tags = {
    Environment = "dev"
    Owner       = "amrendra"
  }
}