#!/bin/bash

# Cargar configuraciones
source "$(dirname "$0")/../config/elasticsearch.conf"
source "$(dirname "$0")/../config/aws.conf"
source "$(dirname "$0")/../utils/es_helpers.sh"
source "$(dirname "$0")/../utils/s3_helpers.sh"

# Validar argumentos
if [ $# -lt 2 ]; then
    echo "Uso: $0 <url_feed> <tipo_feed>"
    exit 1
fi

URL=$1
FEED_TYPE=$2

# Generar un ID único para este feed
FEED_ID=$(echo "$URL" | md5sum | cut -d' ' -f1)
TEMP_FILE=$(mktemp)

echo "Procesando feed: $URL (tipo: $FEED_TYPE, ID: $FEED_ID)"

# Función para procesar un feed RSS
process_rss() {
    local file=$1
    
    # Usar xq para extraer y formatear los items del feed
    cat "$file" | xq -r '.rss.channel.item[] | {
        feed_source_url: "'"$URL"'",
        feed_type: "'"$FEED_TYPE"'",
        item_guid: (if .guid."@isPermaLink" == "false" then .guid."#text" else .guid end) // .link,
        item_title: .title,
        item_url: .link,
        item_description: .description
    }' > "${TEMP_FILE}.items"
    
    # Verificar si se extrajeron items
    if [ ! -s "${TEMP_FILE}.items" ]; then
        echo "No se encontraron items en el feed RSS"
        return 1
    fi
    
    # Procesar cada item
    cat "${TEMP_FILE}.items" | while read -r item; do
        # Generar un ID único para el item
        item_guid=$(echo "$item" | jq -r '.item_guid')
        item_id=$(echo "$item_guid" | md5sum | cut -d' ' -f1)
        
        echo "Procesando item: $item_guid (ID: $item_id)"
        
        # Indexar en ElasticSearch
        es_index_document "$ES_FEED_ITEMS_INDEX" "$item_id" "$item"
        
        # Guardar en S3
        s3_upload_content "$item" "${S3_PREFIX}${item_id}.json"
    done
    
    # Limpiar
    rm "${TEMP_FILE}.items"
    return 0
}

# Función para procesar un feed Atom
process_atom() {
    local file=$1
    
    # Usar xq para extraer y formatear los items del feed
    cat "$file" | xq -r '.feed.entry[] | {
        feed_source_url: "'"$URL"'",
        feed_type: "'"$FEED_TYPE"'",
        item_guid: .id,
        item_title: .title,
        item_url: (if .link."@href" then .link."@href" else .link end),
        item_description: (.summary // .content)
    }' > "${TEMP_FILE}.items"
    
    # Verificar si se extrajeron items
    if [ ! -s "${TEMP_FILE}.items" ]; then
        echo "No se encontraron items en el feed Atom"
        return 1
    fi
    
    # Procesar cada item
    cat "${TEMP_FILE}.items" | while read -r item; do
        # Generar un ID único para el item
        item_guid=$(echo "$item" | jq -r '.item_guid')
        item_id=$(echo "$item_guid" | md5sum | cut -d' ' -f1)
        
        echo "Procesando item: $item_guid (ID: $item_id)"
        
        # Indexar en ElasticSearch
        es_index_document "$ES_FEED_ITEMS_INDEX" "$item_id" "$item"
        
        # Guardar en S3
        s3_upload_content "$item" "${S3_PREFIX}${item_id}.json"
    done
    
    # Limpiar
    rm "${TEMP_FILE}.items"
    return 0
}

# Función para descargar el feed con reintentos
download_feed() {
    local url=$1
    local output=$2
    local retries=$ES_RETRIES
    
    while [ $retries -gt 0 ]; do
        echo "Descargando feed: $url (intentos restantes: $retries)"
        curl -s -L "$url" -o "$output"
        
        if [ $? -eq 0 ] && [ -s "$output" ]; then
            echo "Descarga exitosa"
            return 0
        fi
        
        echo "Error al descargar el feed, reintentando..."
        retries=$((retries - 1))
        sleep $ES_RETRY_DELAY
    done
    
    echo "Error: No se pudo descargar el feed después de $ES_RETRIES intentos"
    return 1
}

# Descargar el feed
download_feed "$URL" "$TEMP_FILE"
if [ $? -ne 0 ]; then
    rm -f "$TEMP_FILE"
    exit 1
fi

# Guardar el feed original en S3
s3_upload_file "$TEMP_FILE" "${S3_PREFIX}raw/${FEED_ID}.xml"

# Procesar el feed según su tipo
if [ "$FEED_TYPE" = "rss" ]; then
    process_rss "$TEMP_FILE"
    result=$?
elif [ "$FEED_TYPE" = "atom" ]; then
    process_atom "$TEMP_FILE"
    result=$?
else
    echo "Tipo de feed desconocido: $FEED_TYPE"
    result=1
fi

# Limpiar
rm -f "$TEMP_FILE"

exit $result