containers=("inference-server:latest" "inference-proxy:latest" "inference-init:latest" "encfs:latest" "skr:latest")
for container in "${containers[@]}"
do
  container_tag=$container
  if [[ "$container" = "encfs:latest" ]]; then
    container_tag="inference-encfs:latest"
  elif [[ "$container" = "skr:latest" ]]; then
    container_tag="inference-skr:latest"
  fi
  
  docker tag $container $CONTAINER_REGISTRY"/"$container_tag
  docker push $CONTAINER_REGISTRY"/"$container_tag
done
