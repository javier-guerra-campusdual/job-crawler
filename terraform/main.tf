provider "aws" {
  region = var.aws_region
}

module "elasticsearch" {
  source = "../modules/elasticsearch"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  instance_type       = var.instance_type
  elasticsearch_version = var.elasticsearch_version
  volume_size         = var.volume_size
  username= var.username
  password= var.password
}

module "compute" {
  source = "../modules/compute"

  project_name    = var.project_name
  environment     = var.environment
  vpc_id         = var.vpc_id
  subnet_ids     = var.subnet_ids
  instance_type  = "t3.large"
  elasticsearch_endpoint = module.elasticsearch.elasticsearch_endpoint
  elasticsearch_sg_id   = module.elasticsearch.elasticsearch_sg_id
}