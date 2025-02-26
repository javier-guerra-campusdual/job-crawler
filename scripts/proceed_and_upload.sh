#!/bin/bash

# Comprobar si se ha proporcionado la URL como argumento
if [ -z "$1" ]; then
  echo "Error: Debes proporcionar la URL del archivo WARC.WAT como argumento."
  exit 1
fi

# URL base de S3
BASE_URL="s3://commoncrawl/"
URL="${BASE_URL}${1}"

echo "Descargando y procesando el archivo desde $URL..."

# Crear un archivo temporal para almacenar las URLs extraídas
archivo_temp=$(mktemp)

# Descargar el archivo desde S3 y procesar el contenido
aws s3 cp "$URL" - | gunzip | grep -E '^{\"Container' | jq '.Envelope."Payload-Metadata"."HTTP-Response-Metadata"."HTML-Metadata"."Head".Link, .Links' | grep -vx "null" | jq .[] | jq -r 'select(.type == "application/rss+xml") | .url' > "$archivo_temp"

# Verificar si se extrajeron URLs
if [ ! -s "$archivo_temp" ]; then
  echo "No se encontraron URLs válidas en el archivo."
  rm "$archivo_temp"
  exit 1
fi

# Configuración de Elasticsearch
ES_HOST="localhost:9200"
ES_USERNAME="elastic"
ES_PASSWORD="campusdual"
INDEX_NAME="url"

# Creamos un archivo temporal para almacenar los datos en formato bulk
bulk_file=$(mktemp)

# Procesar cada URL extraída
while IFS= read -r url; do
  # Descargar el contenido de la URL
  echo "Descargando contenido de $url..."
  contenido_temp=$(mktemp)
  curl -s "$url" -o "$contenido_temp"

  # Verificar si la descarga fue exitosa
  if [ $? -ne 0 ]; then
    echo "Error al descargar $url"
    rm "$contenido_temp"
    continue
  fi

  # Procesar el contenido (aquí puedes agregar cualquier procesamiento adicional que necesites)
  # Por ejemplo, extraer el título o cualquier otra información relevante
  #titulo=$(grep -o '<title>.*</title>' "$contenido_temp" | sed 's/<\/\?title>//g')

  # Formatear cada URL como un documento en formato bulk
  echo '{"index": {}}' >> "$bulk_file"
  echo "{\"url\": \"$url\", \"titulo\": \"$titulo\", \"fecha\": \"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\"}" >> "$bulk_file"

  # Limpiar el archivo temporal
  rm "$contenido_temp"
  echo "Contenido de $url procesado y preparado para subir a Elasticsearch."
done < "$archivo_temp"

# Dividimos el archivo bulk en partes de 1000 documentos
split -l 1000 "$bulk_file" "bulk_chunk_"

# Subimos los datos en lotes a Elasticsearch
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
rm "$archivo_temp"

echo "Proceso completado."
