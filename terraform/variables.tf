variable "aws_region" {
  type        = string
  description = "Región de AWS"
  default     = "eu-west-2"
}


variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
  default     = "job-crawler"
  #default     = "simple-worker-g2"
}

variable "environment" {
  type        = string
  description = "Ambiente (dev/prod)"
  default     = "dev"
}

variable "vpc_id" {
  type        = string
  description = "ID de la VPC"
  default     = "vpc-0c9f03551cb17af5d"
}

variable "subnet_ids" {
  type        = list(string)
  description = "IDs de las subnets privadas"
  default     = ["subnet-0399f98a4db137765", "subnet-0b0842bc836a4b6cb", "subnet-0eb5d5076276d2346"]
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia EC2"
  default     = "t3.xlarge"
}

variable "elasticsearch_version" {
  type        = string
  description = "Versión de Elasticsearch"
  default     = "7.10.2"
}

variable "volume_size" {
  type        = number
  description = "Tamaño del volumen EBS en GB"
  default     = 100
}

variable "username"{
  type=string
  sensitive=true
}

variable "password"{
  type=string
  sensitive=true
}
