# Confidential Inference

This sample demonstrates Confidential Inferencing using Confidential Containers on ACI. 

## Prerequisites
- Azure CLI

## Setup
Edit environment variables in env.sh, and login into your azure subscrption. 
```
az login
```

## Building Inferencing Service
Build server-side containers 
```
./ci/build_server.sh
```

Push containers to container registry
```
az acr login $CONTAINER_REGISTRY
./ci/push_containers.sh
```
ss
## Model Preparation
The first step is to prepare the model for deployment using confidential containers. 

### Create a storage container

## Service Deployment

### Generate a key release policy 

## Run Inferencing Requests