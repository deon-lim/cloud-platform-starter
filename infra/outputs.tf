output "alb_dns_name" {
  value       = module.alb.dns_name
  description = "Hit this URL in your browser to reach the app"
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}