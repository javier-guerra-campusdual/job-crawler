# job-crawler

Este proyecto implementa una pipeline para buscar ofertas de empleo en internet utilizando Common Crawl, AWS S3, EC2 y Elasticsearch.

## Requisitos

- Terraform
- AWS CLI
- Credenciales de AWS
- Credenciales de Elasticsearch

## Despliegue de Infraestructura

1. Configura las variables de entorno necesarias:
   ```bash
   export AWS_ACCESS_KEY_ID=your_access_key_id
   export AWS_SECRET_ACCESS_KEY=your_secret_access_key
   export ELASTICSEARCH_URL=your_elasticsearch_url

2. Despliega la infraestructura con Terraform:
   ```bash	
   cd terraform
   terraform init
   terrafor plan
   terraform apply

3. Ejecutar los scripts de procesamiento:
   ```bash
   ./scripts/graber.sh
   ./scripts/job.sh
   ./upload_to_elasticsearch.sh

4. Ejecutar la pipeline:
   ```bash
   ./github/workflows/crawl.yaml