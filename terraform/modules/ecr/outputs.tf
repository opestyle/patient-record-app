output "backend_repo_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "frontend_repo_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "backend_repo_arn" {
  value = aws_ecr_repository.backend.arn
}

output "frontend_repo_arn" {
  value = aws_ecr_repository.frontend.arn
}

output "backend_repo_name" {
  value = aws_ecr_repository.backend.name
}

output "frontend_repo_name" {
  value = aws_ecr_repository.frontend.name
}
