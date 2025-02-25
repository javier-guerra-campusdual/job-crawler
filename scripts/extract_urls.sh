#!/bin/bash

# Cargar configuración
source "$(dirname "$0")/../config/elasticsearch.conf"

# Función para extraer URLs con paginación
extract_urls() {
    local from=0
    local size=100
    local total_extracted=0
    local total_results=0

    # Primera consulta para obtener el número total de documentos
    total_results=$(curl -s -X GET "${ES_HOST}/${ES_FEED_INDEX}/_count" \
        -H 'Content-Type: application/json' \
        -d '{"query": {"match_all": {}}}' | jq -r '.count')

    echo "Total de feeds encontrados: $total_results" >&2

    # Extraer URLs con paginación
    while [ $total_extracted -lt $total_results ]; do
        echo "Extrayendo desde $from, tamaño $size..." >&2

        # Consulta a ElasticSearch con paginación
        curl -s -X GET "${ES_HOST}/${ES_FEED_INDEX}/_search" \
            -H 'Content-Type: application/json' \
            -d '{
                "query": {"match_all": {}},
                "_source": ["url", "feed_type"],
                "from": '"$from"',
                "size": '"$size"'
            }' | jq -r '.hits.hits[] | {url: ._source.url, feed_type: ._source.feed_type} | .url + "," + .feed_type'

        # Actualizar contadores para la paginación
        total_extracted=$((total_extracted + size))
        from=$((from + size))

        # Si hemos alcanzado o superado el total, salimos del bucle
        if [ $total_extracted -ge $total_results ]; then
            break
        fi
    done
}

# Ejecutar extracción
extract_urls