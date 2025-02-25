ERROR: [1] bootstrap checks failed. You must address the points described in the following [1] lines before starting Elasticsearch.
javier@DESKTOP-JV8P0GR:/mnt/e/CURSO DEVOP&CLOUD_CAMPUSDUAL_CLUSTERTIC/2025-CICD_GithubActions/16_DECIMOSEXTA_CLASE_CICD_25022025/job-crawler$ sysctl vm.max_map_count
vm.max_map_count = 65530
javier@DESKTOP-JV8P0GR:/mnt/e/CURSO DEVOP&CLOUD_CAMPUSDUAL_CLUSTERTIC/2025-CICD_GithubActions/16_DECIMOSEXTA_CLASE_CICD_25022025/job-crawler$ sudo sysctl -w vm.max_map_count=262144
[sudo] password for javier: 
vm.max_map_count = 262144


curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install


aws s3 ls s3://bucket-devops-jgl/job-crawler/ --recursive | grep ".rss.xml" | \
while read file; do
  echo "File: $file"
done

aws s3 cp s3://bucket-devops-jgl/job-crawler/$file - | \

xq -r '
    .rss.channel | {
    "feed_source_url": .atom.link.href,
    "feed_type": "rss",
    "item_guid": "",
    "item_title": .title,,
    "item_url": .link|,
    "item_description": .description,
    }
    ' | \

    curl -X POST "localhost:8080/feed_items/_doc" -H "Content-Type: application/json" -d @
done

aws s3 ls s3://bucket-devops-jgl/json/



aws s3 cp s3://bucket-devops-jgl/job-crawler/ | \
 xargs -I{} -P1 sh -c "aws cp s3://bucket-devops-jgl/job-crawler/{} -"

aws s3 cp "/mnt/e/CURSO DEVOP&CLOUD_CAMPUSDUAL_CLUSTERTIC/2025-CICD_GithubActions/16_DECIMOSEXTA_CLASE_CICD_25022025/job-crawler/scripts/index.json" s3://bucket-devops-jgl/json/index.json
upload: scripts/index.json to s3://bucket-devops-jgl/json/index.json


aws s3 cp "s3://commoncrawl/crawl-data/CC-MAIN-2025-05/wat.paths.gz" - | gunzip -c | xargs -I {} -P 1 ./job.sh "{}"


aws s3 cp "s3://commoncrawl/crawl-data/CC-MAIN-2025-05/wat.paths.gz" - | gunzip -c | xargs -I {} echo {}

aws s3 cp "s3://commoncrawl/crawl-data/CC-MAIN-2025-05/wat.paths.gz" - | gunzip -c | xargs -I {} curl -O {}

aws s3 cp "s3://commoncrawl/crawl-data/CC-MAIN-2025-05/wat.paths.gz" - | gunzip -c | xargs -I {} aws s3 cp {} s3://bucket-devops-jgl/json/


http://localhost:9200/url/_search?pretty




curl -X POST "localhost:9200/job_rss_feeds/_search?scroll=10m" -H 'Content-Type: application/json' -u elastic:campusdual -d'
{
  "size": 3,
  "_source": ["url"],
  "query": {
    "match_all": {}
  }
}
' | jq -r '.hits.hits[]._source.url' | gxargs -P1 -I{} sh -c 'curl -L {} | aws s3 cp - s3://bucket-devops-jgl/json/$(echo {} | sed "s/[^a-zA-Z0-9]//g").rss.xml'



curl -X POST "localhost:9200/job_rss_feeds/_search?scroll=10m" -H 'Content-Type: application/json' -u elastic:campusdual -d'
{
  "size": 3,
  "_source": ["url"],
  "query": {
    "match_all": {}
  }
}
' | jq -r '.hits.hits[]._source.url' | gxargs -P1 -I{} sh -c 'curl -L {} | aws s3 cp - s3://bucket-devops-jgl/json/$(echo {} | sed "s/[^a-zA-Z0-9]//g").rss.xml'