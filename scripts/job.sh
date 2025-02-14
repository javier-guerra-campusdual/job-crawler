#!/bin/bash
# Comprobar si se ha proporcionado la URL como argumento
if [ -z "$1" ]; then
  echo "Error: Debes proporcionar la URL del archivo WARC.WAT como argumento."
  exit 1
fi

# Ruta del archivo WARC.WAT descargado
archivo_descargado="warc.wat"

# Descargar el archivo desde la URL proporcionada
echo "Descargando el archivo desde $1..."
curl -o "$archivo_descargado" "$1"

# Comprobar si la descarga fue exitosa
if [ $? -ne 0 ]; then
  echo "Error: No se pudo descargar el archivo."
  exit 1
fi

# Comprimir el archivo descargado usando gzip con la opción -n
echo "Comprobando si el archivo es un archivo válido para comprimir..."
gzip -n "$archivo_descargado"

# Usamos jq para parsear el JSON y extraer las URLs de los RSS
grep -o '"Link":\[[^]]*\]' "$archivo" | \
    jq -r '.[] | select(.rel=="alternate" and .type=="application/rss+xml") | .url'
