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

## SEGUNDA PARTE ##

# RSS/Atom Feed Processor

Este proyecto implementa un sistema para procesar feeds RSS/Atom mediante un flujo de trabajo distribuido que utiliza ElasticSearch y Amazon S3.

## Descripción General

El sistema realiza las siguientes tareas:
1. Extrae URLs de feeds RSS/Atom almacenadas en ElasticSearch
2. Genera jobs para cada feed que se envían a una cola de trabajos
3. Procesa cada job utilizando workers que descargan el contenido del feed
4. Almacena el contenido en S3 y lo indexa en ElasticSearch

## Requisitos Previos

- Cluster de ElasticSearch configurado
- Acceso a AWS S3 y configuración de AWS CLI
- Herramientas: curl, jq, xq (yq), wget, aws-cli
- Permisos adecuados para acceder a ElasticSearch y S3

### Instalación de Dependencias

```bash
# Instalar jq para procesamiento JSON
sudo apt-get install jq

# Instalar yq/xq para procesamiento XML/YAML
pip install yq

# Configurar AWS CLI
aws configure
```

## Configuración

Antes de ejecutar los scripts, debes configurar los parámetros de ElasticSearch y AWS en los archivos de configuración:

1. Edita `config/elasticsearch.conf`:
```
ES_HOST=http://localhost:9200
ES_FEED_INDEX=feeds
ES_FEED_ITEMS_INDEX=feed_items
```

2. Edita `config/aws.conf`:
```
S3_BUCKET=my-feed-bucket
S3_PREFIX=feeds/
```

## Uso

### 1. Extracción de URLs desde ElasticSearch

```bash
./scripts/extract_urls.sh > feed_urls.txt
```

Este script consulta el índice de ElasticSearch donde se almacenaron previamente las URLs de feeds RSS/Atom y guarda los resultados en un archivo.

### 2. Generación de Jobs

```bash
./scripts/generate_jobs.sh feed_urls.txt
```

Este script lee las URLs del archivo generado anteriormente y crea jobs que se envían a la cola de trabajos.

### 3. Procesamiento de Feeds

```bash
./workers/feed_worker.sh
```

Este script procesa los jobs de la cola, descargando cada feed, transformándolo y almacenando los resultados en S3 y ElasticSearch.

## Monitorización

Se recomienda implementar un sistema de monitorización para supervisar el estado de la cola y los workers. Se pueden utilizar herramientas como CloudWatch si se está trabajando en AWS.

## Solución de Problemas

### Manejo de Duplicados

Para evitar procesar el mismo feed varias veces, se utilizan identificadores únicos (GUIDs) para cada ítem. Antes de insertar un ítem en ElasticSearch, se verifica si ya existe.

### Reintentos

El sistema implementa reintentos automáticos para manejar fallas temporales en la descarga de feeds o en la comunicación con ElasticSearch/S3.

## Contacto

Para preguntas o problemas, por favor contactar al equipo de DevOps.