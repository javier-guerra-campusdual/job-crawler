#!/bin/bash
ES_HOST="172.29.59.22:9200" # aqui configura la ip privada de tu wsl o lo que sea que uses, tambien la linea 82 o cerca de ahi
ES_USERNAME="elastic"
ES_PASSWORD="campusdual"
INDEX_NAME="url_content"

echo "Verificando si el índice existe..."
curl -X PUT "$ES_HOST/$INDEX_NAME" \
    -u "$ES_USERNAME:$ES_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{
          "settings": {
            "number_of_shards": 3,
            "number_of_replicas": 1
          },
          "mappings": {
            "properties": {
              "url": {
                "type": "text"
              },
              "fecha": {
                "type": "date"
              }
            }
          }
        }'




SOURCE_URL="http://$ES_HOST/url/_search"
DEST_URL="http://$ES_HOST/$INDEX_NAME"

# Duración del scroll
SCROLL_DURATION="30m"

# Tamaño de los resultados por solicitud
SIZE=200

# Solicitud inicial para obtener los primeros documentos y el scroll_id
response=$(curl -s -X GET "$SOURCE_URL?scroll=$SCROLL_DURATION" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match_all": {}
  },
  "size": '"$SIZE"'
}' | jq '.')

# Extraer el scroll_id de la respuesta


# Procesar los resultados
while true; do
  scroll_id=$(echo "$response" | jq -r '._scroll_id')
  # Imprimir los resultados actuales
  #echo "$response" | jq '.hits.hits'
  #urls=$(echo "$response" | jq -r '.hits.hits[]._source.url') 
  echo "$response" | jq -r '.hits.hits[]._source.url' | xargs -P1 -I {} sh -c '
    curl -L "{}" | \
    xq -r ".rss | {channel: .channel, item: .channel.item[]} | {
      \"feed_source_url\": .channel.\"atom:link\".\"@href\",
      \"feed_type\": \"rss\",
      \"item_guid\": .item.guid.\"#text\",
      \"item_title\": .item.title,
      \"item_url\": .item.link,
      \"item_description\": .item.description
    }" | \
    jq -c ". | {index: { _index: \"feed_items\" }} , ." '

  curl -X POST "localhost:9200/feed_items/_bulk" -H "Content-Type: application/x-ndjson" --data-binary @- 

  hits=$(echo "$response" | jq '.hits.hits | length')
  
  if [ "$hits" -eq 0 ]; then
    echo "No hay más documentos, finalizando el scroll."
    break
  fi

  # Solicitar la siguiente "página" de resultados usando el scroll_id
  response=$(curl -s -X GET "http://localhost:9200/_search/scroll" -H 'Content-Type: application/json' -d'
  {
    "scroll": "'"$SCROLL_DURATION"'",
    "scroll_id": "'"$scroll_id"'"
  }' | jq '.')

  # Extraer el nuevo scroll_id para la próxima iteración
  scroll_id=$(echo "$response" | jq -r '._scroll_id')
done

# Liberar el scroll al final del proceso
curl -s -X DELETE "http://localhost:9200/_search/scroll" -H 'Content-Type: application/json' -d'
{
  "scroll_id": "'"$scroll_id"'"
}'
echo "Scroll finalizado y recursos liberados."



