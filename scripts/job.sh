#!/bin/bash

# Comprobar si se ha proporcionado la URL como argumento
if [ -z "$1" ]; then
  echo "Error: Debes proporcionar la URL del archivo WARC.WAT como argumento."
  exit 1
fi

# Ruta del archivo WARC.WAT descargado
archivo_descargado="warcjob.wat"

# URL base de S3
BASE_URL="s3://commoncrawl/"

# Concatenar la URL base con el argumento pasado
URL="${BASE_URL}${1}"

echo "Descargando el archivo desde $URL..."

# Descargar el archivo desde S3 usando AWS CLI
aws s3 cp "$URL" "${archivo_descargado}.gz"

# Comprobar si la descarga fue exitosa
if [ $? -ne 0 ]; then
  echo "Error: No se pudo descargar el archivo."
  exit 1
fi

# Descomprimir el archivo descargado
echo "Descomprimiendo el archivo ${archivo_descargado}.gz..."
gunzip -f "${archivo_descargado}.gz"

# Comprobar si la descompresión fue exitosa
if [ $? -ne 0 ]; then
  echo "Error: No se pudo descomprimir el archivo."
  exit 1
fi

# Procesar los enlaces RSS dentro del archivo descomprimido
echo "Buscando enlaces RSS..."

grep "Container" CC-MAIN-20241201162023-20241201192023-00022.warc.wat | jq ".Envelope" | jq '.["Payload-Metadata"]' | jq '.["HTTP-Response-Metadata"]' | jq '.["HTML-Metadata"]' | jq '.["Head"].["Link"],.["Links"]' | grep -vx "null" | jq .[] | jq -r 'select(.type == "application/rss+xml") | .url' | grep  "http"

# Eliminar el archivo descomprimido
rm -f "$archivo_descargado"
echo "Archivo descomprimido y procesado correctamente."




#sed -e '/^WARC-/d' -e '/^Content-/d' -e '/{/,/}/p' "small-data" > output.json0