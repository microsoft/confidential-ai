DOCKER_BUILDKIT=1 docker build ../server/triton -t inference-server 
DOCKER_BUILDKIT=1 docker build ../server/proxy -t inference-proxy
DOCKER_BUILDKIT=1 docker build ../server/init -t inference-init
