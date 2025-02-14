terraform {
  backend "s3" {
    bucket  = "proyecto-devops-grupo-dos"         # Nombre de tu bucket S3
    key     = "elastic-search/terraform.tfstate"   # Ruta y nombre del archivo de estado
    region  = "eu-west-2"                          # Región del bucket
    encrypt = true
  }
}
