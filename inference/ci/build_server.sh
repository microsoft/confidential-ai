DOCKER_BUILDKIT=1 docker build ${PWD}/../server/triton -t inference-server 
DOCKER_BUILDKIT=1 docker build ${PWD}/../server/proxy -t inference-proxy
DOCKER_BUILDKIT=1 docker build ${PWD}/../server/init -t inference-init

# Build encrypted file system sidecar container
pushd .
cd ${PWD}/../external/confidential-sidecar-containers
./buildall.sh
popd