#!/bin/bash

# Configuración de Elasticsearch
ES_HOST="localhost:9200"
ES_USERNAME="elastic"
ES_PASSWORD="campusdual"
INDEX_NAME="job_rss_feeds"

# Verificamos si se pasó un argumento con el archivo de URLs
if [ -z "$1" ]; then
  echo "Error: Debes proporcionar la URL del archivo WARC.WAT como argumento."
  exit 1
fi


# Creamos un archivo temporal para almacenar los datos en formato bulk
bulk_file=$(mktemp)

# Leemos las URLs desde la entrada estándar y las convertimos en formato bulk
echo "Preparando datos para Elasticsearch..."
while IFS= read -r url; do
  # Formateamos cada URL como un documento en formato bulk
  echo '{"index": {}}' >> "$bulk_file"
  echo "{\"url\": \"$url\", \"fecha\": \"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\"}" >> "$bulk_file"
done < "$1"

# Dividimos el archivo bulk en partes de 1000 documentos
split -l 1000 "$bulk_file" "bulk_chunk_"

# Subimos los datos en lotes
for chunk in bulk_chunk_*; do
  echo "Subiendo lote a Elasticsearch..."
  curl -X POST "$ES_HOST/$INDEX_NAME/_bulk" \
    -u "$ES_USERNAME:$ES_PASSWORD" \
    -H "Content-Type: application/json" \
    --data-binary @"$chunk"
done

# Limpiar archivos temporales
rm "$bulk_file"
rm bulk_chunk_*

echo "Proceso completado."
