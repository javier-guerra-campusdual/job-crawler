#!/bin/bash

# Comprobar si se ha proporcionado la URL como argumento
if [ -z "$1" ]; then
  echo "Error: Debes proporcionar la URL del archivo WARC.WAT como argumento."
  exit 1
fi

# URL base de S3
BASE_URL="s3://commoncrawl/"

# Concatenar la URL base con el argumento pasado
URL="${BASE_URL}${1}"

echo "Descargando y procesando el archivo desde $URL..."

# Descargar el archivo desde S3, descomprimirlo y procesarlo todo en un solo pipeline
resultado=$(aws s3 cp "$URL" - | gunzip -c | grep "Container" | \
  jq '.Envelope | .["Payload-Metadata"] | .["HTTP-Response-Metadata"] | .["HTML-Metadata"] | .["Head"].["Link"],.["Links"]' | \
  grep -vx "null" | jq .[] | jq -r 'select(.type == "application/rss+xml") | .url' | \
  grep "http")

# Verificamos si hubo algún resultado
if [ -z "$resultado" ]; then
  echo "No se encontraron enlaces RSS."
  exit 1
fi

# Subir el resultado a Elasticsearch
echo "Subiendo los resultados a Elasticsearch..."
#./upload_to_elasticsearch.sh "$resultado"

echo "Proceso completado."
