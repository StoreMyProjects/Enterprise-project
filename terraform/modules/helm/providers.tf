provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", var.cluster_name,
      "--region", var.region
    ]
  }
}

provider "helm" {
  kubernetes = {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks", "get-token",
        "--cluster-name", var.cluster_name,
        "--region", var.region
      ]
    }
  }
}

provider "kubectl" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", var.cluster_name,
      "--region", var.region
    ]
  }
}