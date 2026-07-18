output "rds_secret_arn" {
  value = aws_secretsmanager_secret.rds.arn
}

output "app_secret_arn" {
  value = aws_secretsmanager_secret.app.arn
}
