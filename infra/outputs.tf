output "alb_dns_name" {
  value       = module.alb.dns_name
  description = "Production ALB URL"
}

output "alb_staging_dns_name" {
  value       = module.alb_staging.dns_name
  description = "Staging ALB URL"
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}