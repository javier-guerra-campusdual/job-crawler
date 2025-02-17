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

# O si prefieres usar `xargs` para paralelizar
 aws s3 cp "$bucket_url" - | gunzip -c | xargs -I {} -P 4 ./job.sh "{}"

echo "Proceso completado."
