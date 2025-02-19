#!/bin/bash

# URL de S3 del archivo comprimido de forma manual
bucket_url="s3://commoncrawl/crawl-data/CC-MAIN-2025-05/wat.paths.gz"

# Nombre del archivo comprimido (no es necesario almacenar el archivo descomprimido)
archivo_comprimido="archivo_descargado.gz"

# Descargar el archivo desde S3 usando AWS CLI y procesar directamente desde el pipe
echo "Descargando y procesando el archivo desde S3: $bucket_url..."

# Usamos `aws s3 cp` para obtener el archivo comprimido y lo descomprimimos directamente en el pipe con `gunzip`
#aws s3 cp "$bucket_url" - | gunzip -c | while IFS= read -r linea; do
  # Pasar cada línea a job.sh (directamente desde el pipe)
#  ./job.sh "$linea"
#done
ES_HOST="localhost:9200"
ES_USERNAME="elastic"
ES_PASSWORD="campusdual"
INDEX_NAME="url"

echo "Verificando si el índice existe..."
curl -X PUT "$ES_HOST/$INDEX_NAME" \
    -u "$ES_USERNAME:$ES_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{
          "settings": {
            "number_of_shards": 3,
            "number_of_replicas": 1
          },
          "mappings": {
            "properties": {
              "url": {
                "type": "text"
              },
              "fecha": {
                "type": "date"
              }
            }
          }
        }'


# O si prefieres usar `xargs` para paralelizar
aws s3 cp "$bucket_url" - | gunzip -c | xargs -I {} -P 1 ./job.sh "{}"

echo "Proceso completado."
