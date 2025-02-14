output "elasticsearch_endpoint" {
  description = "DNS del ALB de Elasticsearch"
  value       = aws_lb.elasticsearch.dns_name
}
