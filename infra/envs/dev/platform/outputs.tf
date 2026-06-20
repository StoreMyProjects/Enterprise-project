
output "redis_primary_endpoint" {
  value = module.helm.redis_primary_endpoint
}

output "redis_reader_endpoint" {
  value = module.helm.redis_reader_endpoint
}

output "redis_port" {
  value = module.helm.redis_port
}