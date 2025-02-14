#!/bin/bash

# Definir nombres de archivos temporales
INDEX_FILE="crawl_indexes.txt"
WAT_LIST_FILE="all_wat_files.txt"

# Limpiar archivos previos si existen
rm -f $INDEX_FILE $WAT_LIST_FILE

# Crear archivos vacíos
touch $INDEX_FILE $WAT_LIST_FILE

# Obtener los índices desde el archivo JSON oficial de Common Crawl
echo "Obteniendo índices de Common Crawl desde la API..."
curl -s https://index.commoncrawl.org/collinfo.json | jq -r '.[].id' > $INDEX_FILE

# Verificar si se obtuvieron índices correctamente
if [[ ! -s $INDEX_FILE ]]; then
    echo "Error: No se encontraron índices de Common Crawl."
    exit 1
fi

echo "Índices obtenidos:"
cat $INDEX_FILE

# Obtener todas las rutas de archivos WAT desde los índices extraídos
echo "Obteniendo rutas de archivos WAT..."
while read index; do
    curl -s https://data.commoncrawl.org/crawl-data/$index/wat.paths >> $WAT_LIST_FILE
done < $INDEX_FILE

# Verificar si se encontraron archivos WAT
if [[ ! -s $WAT_LIST_FILE ]]; then
    echo "Error: No se encontraron archivos WAT."
    exit 1
fi

echo "Total de archivos WAT encontrados: $(wc -l < $WAT_LIST_FILE)"






























