output "elasticsearch_endpoint" {
  description = "Endpoint del cluster de Elasticsearch"
  value       = aws_lb.elasticsearch.dns_name
}

output "elasticsearch_sg_id" {
  description = "ID del security group de Elasticsearch"
  value       = aws_security_group.elasticsearch.id
}

output "elasticsearch_secret_arn" {
  description = "ARN del secreto de credenciales de Elasticsearch"
  value       = aws_secretsmanager_secret.es_credentials.arn
}