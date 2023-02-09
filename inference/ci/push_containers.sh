containers=('inference-server:latest' 'inference-proxy:latest' 'inference-init:latest' 'encfs:latest')
for container in $containers; do
  docker tag $container $CONTAINER_REGISTRY"/"$container
  docker push $CONTAINER_REGISTRY"/"$container
done
