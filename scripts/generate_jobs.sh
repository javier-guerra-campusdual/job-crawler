#!/bin/bash

# Cargar configuraciones
source "$(dirname "$0")/../config/elasticsearch.conf"
source "$(dirname "$0")/../config/aws.conf"

# Validar argumentos
if [ $# -lt 1 ]; then
    echo "Uso: $0 <archivo_urls>"
    exit 1
fi

URL_FILE=$1

# Verificar que el archivo de URLs existe
if [ ! -f "$URL_FILE" ]; then
    echo "Error: El archivo $URL_FILE no existe."
    exit 1
fi

# Función para generar un job para cada URL de feed
process_url() {
    local line=$1
    local url=$(echo $line | cut -d',' -f1)
    local feed_type=$(echo $line | cut -d',' -f2)
    
    # Generar un identificador único para el job
    job_id=$(echo $url | md5sum | cut -d' ' -f1)
    
    echo "Generando job para: $url (tipo: $feed_type)" >&2
    
    # Generar el comando que será ejecutado por el worker
    cat <<EOL
#!/bin/bash
# Job ID: $job_id
# URL: $url
# Tipo: $feed_type

# Descargar el feed
echo "Descargando feed: $url" >&2
TEMP_FILE=\$(mktemp)
curl -s -L "$url" -o \$TEMP_FILE

# Verificar si la descarga fue exitosa
if [ \$? -ne 0 ]; then
    echo "Error al descargar el feed: $url" >&2
    exit 1
fi

# Procesar el feed según su tipo
if [ "$feed_type" = "rss" ]; then
    # Procesar RSS
    cat \$TEMP_FILE | xq -r '.rss.channel.item[] | {
        feed_source_url: "$url",
        feed_type: "$feed_type",
        item_guid: (if .guid."@isPermaLink" == "false" then .guid."#text" else .guid end) // .link,
        item_title: .title,
        item_url: .link,
        item_description: .description
    }' | while read -r item; do
        # Enviar cada ítem a ElasticSearch
        curl -s -X POST "${ES_HOST}/${ES_FEED_ITEMS_INDEX}/_doc" \\
            -H 'Content-Type: application/json' \\
            -d "\$item"
        
        # Guardar en S3
        echo "\$item" | aws s3 cp - s3://${S3_BUCKET}/${S3_PREFIX}\$(echo \$item | jq -r '.item_guid' | md5sum | cut -d' ' -f1).json
    done
elif [ "$feed_type" = "atom" ]; then
    # Procesar Atom
    cat \$TEMP_FILE | xq -r '.feed.entry[] | {
        feed_source_url: "$url",
        feed_type: "$feed_type",
        item_guid: .id,
        item_title: .title,
        item_url: (if .link."@href" then .link."@href" else .link end),
        item_description: (.summary // .content)
    }' | while read -r item; do
        # Enviar cada ítem a ElasticSearch
        curl -s -X POST "${ES_HOST}/${ES_FEED_ITEMS_INDEX}/_doc" \\
            -H 'Content-Type: application/json' \\
            -d "\$item"
        
        # Guardar en S3
        echo "\$item" | aws s3 cp - s3://${S3_BUCKET}/${S3_PREFIX}\$(echo \$item | jq -r '.item_guid' | md5sum | cut -d' ' -f1).json
    done
else
    echo "Tipo de feed desconocido: $feed_type" >&2
    exit 1
fi

# Limpiar
rm \$TEMP_FILE
echo "Job completado para: $url" >&2
EOL
}

# Leer cada línea del archivo de URLs y generar un job para cada una
cat "$URL_FILE" | while read -r line; do
    # Generar el job
    job_script=$(process_url "$line")
    
    # Aquí podrías enviar el job a una cola real como SQS
    # Para simplificar, lo guardaremos en un directorio de jobs
    job_dir="$(dirname "$0")/../jobs"
    mkdir -p "$job_dir"
    
    # Crear un archivo de job
    job_id=$(echo "$line" | cut -d',' -f1 | md5sum | cut -d' ' -f1)
    job_file="${job_dir}/${job_id}.sh"
    
    echo "$job_script" > "$job_file"
    chmod +x "$job_file"
    
    echo "Job generado: $job_file"
done

echo "Generación de jobs completada."