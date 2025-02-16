output "elasticsearch_endpoint" {
  description = "Endpoint del cluster de Elasticsearch"
  value       = module.elasticsearch.elasticsearch_endpoint
}

output "elasticsearch_secret_arn" {
  description = "ARN del secreto de credenciales de Elasticsearch"
  value       = module.elasticsearch.elasticsearch_secret_arn
}

output "compute_asg_name" {
  description = "Nombre del Auto Scaling Group de compute"
  value       = module.compute.asg_name
}