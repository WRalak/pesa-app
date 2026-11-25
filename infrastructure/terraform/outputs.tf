output "api_alb_dns" { value = aws_lb.public.dns_name }
output "admin_alb_dns" { value = aws_lb.admin.dns_name }
output "ecr_repositories" { value = { for k, r in aws_ecr_repository.repo : k => r.repository_url } }
output "ecs_cluster" { value = aws_ecs_cluster.main.name }
output "app_secret_arn" { value = aws_secretsmanager_secret.app.arn }
output "uploads_bucket" { value = aws_s3_bucket.uploads.id }
