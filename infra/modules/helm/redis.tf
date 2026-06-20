resource "random_password" "redis_auth_token" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "redis" {
  name = "redis-secrets"
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id = aws_secretsmanager_secret.redis.id

  secret_string = jsonencode({
    host     = aws_elasticache_replication_group.redis.primary_endpoint_address
    port     = aws_elasticache_replication_group.redis.port
    password = random_password.redis_auth_token.result
  })
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-subnet-group"
  subnet_ids = var.private_subnets
}

resource "aws_security_group" "redis" {
  name_prefix = "redis-sg"
  vpc_id      = var.vpc_id
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "exploreexpeditions-redis"
  description = "Application Redis"

  node_type = "cache.t4g.micro"
  num_cache_clusters = 1
  engine = "redis"
  parameter_group_name = "default.redis7"

  subnet_group_name = aws_elasticache_subnet_group.redis.name

  security_group_ids = [
    aws_security_group.redis.id
  ]

  transit_encryption_enabled = true
  at_rest_encryption_enabled = true

  auth_token = random_password.redis_auth_token.result
}

resource "aws_security_group_rule" "eks_to_redis" {
  type = "ingress"

  protocol = "tcp"
  from_port = 6379
  to_port   = 6379

  security_group_id = aws_security_group.redis.id
  source_security_group_id = var.cluster_security_group_id
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  namespace  = "external-secrets"
  create_namespace = true

  repository = "https://charts.external-secrets.io"
  chart = "external-secrets"

  timeout = 600
}

resource "aws_iam_policy" "external_secrets" {
  name   = "ExternalSecretsSecretsManagerPolicy"
  policy = file("${path.module}/redis_iam_policy.json")
}

resource "aws_iam_role" "external_secrets" {
  name = "external-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "pods.eks.amazonaws.com"
      }

      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  role       = aws_iam_role.external_secrets.name
  policy_arn = aws_iam_policy.external_secrets.arn
}

resource "aws_eks_pod_identity_association" "external_secrets" {
  cluster_name = var.cluster_name
  namespace = "external-secrets"
  service_account = "external-secrets"

  role_arn = aws_iam_role.external_secrets.arn
}