#!/bin/bash

# URL de S3 del archivo comprimido de forma manual
bucket_url="s3://commoncrawl/crawl-data/CC-MAIN-2025-05/wat.paths.gz"

# Nombre del archivo comprimido y descomprimido
archivo_comprimido="archivo_descargado.gz"
archivo_descomprimido="archivo_descargado"

# Descargar el archivo desde S3 usando AWS CLI
echo "Descargando el archivo desde S3: $bucket_url..."
aws s3 cp "$bucket_url" "$archivo_comprimido"

# Comprobar si la descarga fue exitosa
if [ $? -ne 0 ]; then
  echo "Error: No se pudo descargar el archivo desde S3."
  exit 1
fi

# Descomprimir el archivo descargado
echo "Descomprimiendo el archivo $archivo_comprimido..."
gunzip -f "$archivo_comprimido"  # Usamos -f para sobrescribir el archivo descomprimido si ya existe

# Comprobar si la descompresión fue exitosa
if [ $? -ne 0 ]; then
  echo "Error: No se pudo descomprimir el archivo."
  exit 1
fi

# Procesar cada línea del archivo descomprimido y pasarla a job.sh
echo "Procesando cada línea del archivo descomprimido..."

while IFS= read -r linea; do
  # Pasar cada línea a job.sh
  ./job.sh "$linea"
done < "$archivo_descomprimido"

echo "Proceso completado."
