# Configuración de Elasticsearch
ES_HOST="172.29.59.22:9200"  # Configura la IP privada de tu WSL u otro entorno
ES_USERNAME="elastic"
ES_PASSWORD="campusdual"
INDEX_NAME="url_content"

# Verificar si el índice existe y crearlo si es necesario
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
              "url": { "type": "text" },
              "fecha": { "type": "date" }
            }
          }
        }'

# Configuración del scroll y la consulta
SOURCE_URL="http://$ES_HOST/url/_search"
DEST_URL="http://$ES_HOST/$INDEX_NAME"
SCROLL_DURATION="30m"
SIZE=200

# Obtener los primeros documentos y el scroll_id
response=$(curl -s -X GET "$SOURCE_URL?scroll=$SCROLL_DURATION" \
  -H 'Content-Type: application/json' \
  -d'{
    "query": { "match_all": {} },
    "size": '"$SIZE"'
  }' | jq '.')

# Bucle para procesar los resultados mientras haya documentos
while true; do
  scroll_id=$(echo "$response" | jq -r '._scroll_id')
  
  # Extraer y procesar URLs y almacenar en response
  response=$(echo "$response" | jq -r '.hits.hits[]._source.url' | xargs -I {} -P 5 ./app add -timeout 20 -cmd '
    curl -X POST "localhost:9200/job_rss_feeds/_search?scroll=10m" \
      -H "Content-Type: application/json" \
      -u elastic:campusdual \
      -d "{
        \"size\": 3,
        \"_source\": [\"url\"],
        \"query\": { \"match_all\": {} }
      }"' | jq -r '.hits.hits[]._source.url')

  # Procesar contenido directamente desde response
  echo "$response" | jq -c ". | {index: { _index: \"feed_items\" }} , ."

  # Verificar si hay más documentos
  hits=$(echo "$response" | jq '.hits.hits | length')
  if [ "$hits" -eq 0 ]; then
    echo "No hay más documentos, finalizando el scroll."
    break
  fi

  # Obtener la siguiente página de resultados
  response=$(curl -s -X GET "$ES_HOST/_search/scroll" \
    -H 'Content-Type: application/json' \
    -d'{
      "scroll": "'$SCROLL_DURATION'",
      "scroll_id": "'$scroll_id'"
    }' | jq '.')

  # Extraer el nuevo scroll_id
  scroll_id=$(echo "$response" | jq -r '._scroll_id')
done

# Liberar el scroll al final del proceso
echo "Liberando scroll y finalizando..."
curl -s -X DELETE "$ES_HOST/_search/scroll" \
  -H 'Content-Type: application/json' \
  -d'{ "scroll_id": "'$scroll_id'" }'

echo "Proceso finalizado con éxito."
