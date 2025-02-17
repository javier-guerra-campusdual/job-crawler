#!/bin/bash

# Configuración de Elasticsearch
ES_HOST="${ES_HOST}"
ES_USERNAME="${ES_USERNAME}"
ES_PASSWORD="${ES_PASSWORD}"
INDEX_NAME="job_rss_feeds"
#ELASTICSEARCH_HOST="http://<IP-DE-EC2>:9200"


# Archivo de URLs
urls_file="urls.txt"

# Verificar si el archivo existe
if [ ! -f "$urls_file" ]; then
  echo "Error: Archivo $urls_file no encontrado."
  exit 1
fi


# Crear índice con mapping adecuado
curl -X PUT -u "${ES_USERNAME}:${ES_PASSWORD}" "${ES_HOST}/${INDEX_NAME}" -H "Content-Type: application/json" -d '{
  "mappings": {
    "properties": {
      "url": { "type": "keyword" },
      "title": { "type": "text" },
      "description": { "type": "text" },
      "company": { "type": "keyword" },
      "location": { "type": "keyword" },
      "date_found": { "type": "date" }
    }
  }
}'

# Leer cada URL y enviarla a Elasticsearch
echo "Subiendo URLs a Elasticsearch..."
while IFS= read -r url; do
  curl -X POST -u "${ES_USERNAME}:${ES_PASSWORD}" "${ES_HOST}/${INDEX_NAME}/_doc/" \
    -H "Content-Type: application/json" \
    -d "{
      \"url\": \"$url\",
      \"date_found\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
    }"
done < "$urls_file"

echo "Proceso completado."




































# Leer cada URL y enviarla a Elasticsearch
#echo "Subiendo URLs a Elasticsearch..."
#while IFS= read -r url; do
#  curl -s -X POST "$ELASTICSEARCH_HOST/$INDEX_NAME/_doc/" \
#    -H "Content-Type: application/json" \
#    -d "{\"url\": \"$url\"}"
#done < "$urls_file"

#echo "Proceso completado."
