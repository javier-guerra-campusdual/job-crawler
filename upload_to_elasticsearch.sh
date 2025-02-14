#!/bin/bash

# Configuración de Elasticsearch
ELASTICSEARCH_HOST="http://<IP-DE-EC2>:9200"
INDEX_NAME="job_rss_feeds"

# Archivo de URLs
urls_file="urls.txt"

# Verificar si el archivo existe
if [ ! -f "$urls_file" ]; then
  echo "Error: Archivo $urls_file no encontrado."
  exit 1
fi

# Leer cada URL y enviarla a Elasticsearch
echo "Subiendo URLs a Elasticsearch..."
while IFS= read -r url; do
  curl -s -X POST "$ELASTICSEARCH_HOST/$INDEX_NAME/_doc/" \
    -H "Content-Type: application/json" \
    -d "{\"url\": \"$url\"}"
done < "$urls_file"

echo "Proceso completado."
