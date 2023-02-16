containers=("inference-server:latest" "inference-proxy:latest" "inference-init:latest" "encfs:latest")
for container in "${containers[@]}"
do
  container_tag=$container
  if [[ "$container" = "encfs:latest" ]]; then
    container_tag="inference-encfs:latest"
  fi
  
  docker tag $container $CONTAINER_REGISTRY"/"$container_tag
  docker push $CONTAINER_REGISTRY"/"$container_tag
done
