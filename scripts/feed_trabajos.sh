#!/bin/bash

# Dirección de Elasticsearch (ajústalo según tu configuración)
ELASTICSEARCH_URL="http://172.20.178.149:9200/url_content/_search"

# Consultar Elasticsearch para obtener los documentos que contienen el campo `url_content`
# Aquí asumimos que el campo 'url_content' contiene los enlaces
curl -s -X GET "$ELASTICSEARCH_URL" -H "Content-Type: application/json" -d '{
  "_source": ["url_content"],
  "query": {
    "exists": {
      "field": "url_content"
    }
  }
}' | jq -r '.hits.hits[]._source.url_content' | while read -r url; do
  # Verificar si la URL es un RSS (comienza con <?xml o <rss)
  if [[ "$url" =~ ^(http|https):// ]]; then
    content=$(curl -s "$url")
    # Comprobar si contiene un RSS XML
    if echo "$content" | grep -iq '<?xml' && echo "$content" | grep -iq '<rss'; then
      echo "RSS válido encontrado: $url"
    else
      echo "No es un RSS válido: $url"
    fi
  else
    echo "URL no válida: $url"
  fi
done
