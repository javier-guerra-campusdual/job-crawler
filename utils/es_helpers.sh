#!/bin/bash

# Cargar configuración
source "$(dirname "$0")/../config/elasticsearch.conf"

# Función para verificar si un documento ya existe en ElasticSearch
es_document_exists() {
    local index=$1
    local id=$2
    
    local result=$(curl -s -X GET "${ES_HOST}/${index}/_doc/${id}" \
        -H 'Content-Type: application/json')
    
    # Verificar si el documento existe
    echo "$result" | jq -r '.found'
}

# Función para indexar un documento en ElasticSearch
es_index_document() {
    local index=$1
    local id=$2
    local document=$3
    
    # Verificar si el documento ya existe
    local exists=$(es_document_exists "$index" "$id")
    
    if [ "$exists" = "true" ]; then
        # Actualizar documento existente
        curl -s -X PUT "${ES_HOST}/${index}/_doc/${id}" \
            -H 'Content-Type: application/json' \
            -d "$document"
    else
        # Crear nuevo documento
        curl -s -X POST "${ES_HOST}/${index}/_doc/${id}" \
            -H 'Content-Type: application/json' \
            -d "$document"
    fi
}

# Función para crear un índice de ElasticSearch si no existe
es_create_index() {
    local index=$1
    local mapping=$2
    
    # Verificar si el índice existe
    local index_exists=$(curl -s -X HEAD "${ES_HOST}/${index}" -o /dev/null -w '%{http_code}')
    
    if [ "$index_exists" = "404" ]; then
        # Crear el índice con el mapping especificado
        curl -s -X PUT "${ES_HOST}/${index}" \
            -H 'Content-Type: application/json' \
            -d "$mapping"
        echo "Índice creado: $index"
    else
        echo "El índice ya existe: $index"
    fi
}

# Función para buscar documentos en ElasticSearch
es_search() {
    local index=$1
    local query=$2
    
    curl -s -X GET "${ES_HOST}/${index}/_search" \
        -H 'Content-Type: application/json' \
        -d "$query"
}

# Crear el índice feed_items si no existe
create_feed_items_index() {
    local mapping='{
        "mappings": {
            "properties": {
                "feed_source_url": {"type": "keyword"},
                "feed_type": {"type": "keyword"},
                "item_guid": {"type": "keyword"},
                "item_title": {"type": "text"},
                "item_url": {"type": "keyword"},
                "item_description": {"type": "text"}
            }
        }
    }'
    
    es_create_index "$ES_FEED_ITEMS_INDEX" "$mapping"
}

# Crear el índice feed_items automáticamente
create_feed_items_index