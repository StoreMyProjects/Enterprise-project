resource "random_password" "redis_auth_token" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "redis" {
  name = "redis-secrets"
  recovery_window_in_days = 0
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
  description          = "Application Redis"

  node_type            = "cache.t4g.micro"
  num_cache_clusters   = 1
  engine               = "redis"
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

  protocol  = "tcp"
  from_port = 6379
  to_port   = 6379

  security_group_id        = aws_security_group.redis.id
  source_security_group_id = var.node_security_group_id
}
