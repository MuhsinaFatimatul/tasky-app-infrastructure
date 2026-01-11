
output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer" {
  value = module.eks.cluster_oidc_issuer_url
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "nat_gateway_id" {
  value       = try(module.vpc.nat_gateway_ids[0], "")
  description = "NAT Gateway ID (first) if available"
}

output "nat_eip_allocation_id" {
  value       = try(module.vpc.eip_ids[0], "")
  description = "EIP allocation ID (first) if available"
}

output "nat_subnet_id" {
  value = module.vpc.public_subnets[0]
}

output "private_subnet_id" {
  value = module.vpc.private_subnets[0]
}

output "s3_backup_bucket" {
  value = aws_s3_bucket.mongodb_backups.bucket
}

output "iam_instance_profile" {
  value = aws_iam_instance_profile.instance_profile.name
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "mongodb_public_ip" {
  value       = aws_instance.mongodb.public_ip
  description = "Public IP address of the MongoDB EC2 instance"
}

output "mongodb_private_ip" {
  value       = aws_instance.mongodb.private_ip
  description = "Private IP address of the MongoDB EC2 instance"
}