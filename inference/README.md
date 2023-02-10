# Confidential Inference

This sample demonstrates Confidential Inferencing using Confidential Containers on ACI. 

## Prerequisites
- Azure CLI

## Setup
Edit environment variables in env.sh, and login into your azure subscrption. 
```
az login
az account set --subscription <YOUR_SUBSCRPTION_NAME>
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

## Model Preparation
Place the models you would like to serve under the ```models/model_repository``` folder. You can use the following script to fetch samples models.
```
./models/fetch_models.sh
```

### Sign and Encrypt Models
Use the following script to sign and encrypt models using fresh keys. The keys are stored locally. 
```
./models/sign_and_encrypt_models.sh
```

### Upload models
Create a resource group, storage account and blob storage containers to store your models. This is a one time step.
```
./models/create_storage_container.sh
```
Upload encrypt model to storage container. 
```
./models/upload_encrypted_models.sh
```

### Provision keys to Azure Key Vault
```
./models/import_keys.sh
```
## Service Deployment

## Client Setup

## Run Inferencing Requests