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

archivo_temp=$(mktemp)
# Descargar el archivo desde S3 y descomprimirlo en una variable
aws s3 cp "$URL" - | gunzip | grep -E '^{\"Container' | jq '.Envelope.["Payload-Metadata"].["HTTP-Response-Metadata"].["HTML-Metadata"].["Head"].Link, .Links' | grep -vx "null" | jq .[] | jq -r 'select(.type == "application/rss+xml") | .url' > "$archivo_temp"


#printf "%s\n" "$archivo_temp" >> output.txt
./upload.sh "$archivo_temp"

rm "$archivo_temp"

echo "Proceso completado."
