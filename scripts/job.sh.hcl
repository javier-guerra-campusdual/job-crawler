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

# Subir cada URL extraída a S3
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

  # Subir el contenido al bucket de S3
  nombre_archivo=$(basename "$url")
  aws s3 cp "$contenido_temp" "s3://bucket-devops-jgl/json/$nombre_archivo"

  # Limpiar el archivo temporal
  rm "$contenido_temp"
  echo "Contenido de $url subido a S3 como $nombre_archivo."
done < "$archivo_temp"

# Limpiar el archivo temporal de URLs
rm "$archivo_temp"

echo "Proceso completado."
