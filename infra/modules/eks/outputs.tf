output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.this.arn
}

output "cluster_ca" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_provider_url" {
  value = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "cluster_security_group_id" {
  value = aws_security_group.cluster.id
}

output "node_security_group_id" {
  value = aws_security_group.node.id
}