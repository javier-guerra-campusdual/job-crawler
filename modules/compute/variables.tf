variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
}

variable "environment" {
  type        = string
  description = "Ambiente (dev/prod)"
}

variable "vpc_id" {
  type        = string
  description = "ID de la VPC"
}

variable "subnet_ids" {
  type        = list(string)
  description = "IDs de las subnets privadas"
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia EC2"
  default     = "t3.large"
}

variable "elasticsearch_endpoint" {
  type        = string
  description = "Endpoint del cluster de Elasticsearch"
}

variable "elasticsearch_sg_id" {
  type        = string
  description = "ID del security group de Elasticsearch"
}