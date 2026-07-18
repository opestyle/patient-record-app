output "vpc_id" {
  value = try(module.vpc[0].vpc_id, null)
}

output "cluster_name" {
  value = try(module.eks[0].cluster_name, null)
}

output "cluster_endpoint" {
  value = try(module.eks[0].cluster_endpoint, null)
}

output "ecr_backend_repository" {
  value = try(module.ecr[0].backend_repo_url, null)
}

output "ecr_frontend_repository" {
  value = try(module.ecr[0].frontend_repo_url, null)
}

output "app_bucket_name" {
  value = try(module.s3[0].bucket_name, null)
}

output "rds_endpoint" {
  value = try(module.rds[0].db_endpoint, null)
}
