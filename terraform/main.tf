provider "aws" {
  region = var.aws_region
}

module "elasticsearch" {
  source = "../modules/elasticsearch"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids

  elasticsearch_version = var.elasticsearch_version
  volume_size         = var.volume_size
  private_key_path=var.private_key_path
  public_key_path=var.public_key_path
}

/*module "compute" {
  source = "../modules/compute"

  project_name    = var.project_name
  environment     = var.environment
  vpc_id         = var.vpc_id
  subnet_ids     = var.subnet_ids
  instance_type  = "t3.large"
  elasticsearch_endpoint = module.elasticsearch.elasticsearch_endpoint
  elasticsearch_sg_id   = module.elasticsearch.elasticsearch_sg_id
}*/