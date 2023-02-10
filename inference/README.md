# Confidential Inference

This sample demonstrates Confidential Inferencing using Confidential Containers on ACI. 

## Prerequisites
- Azure subscription
- Ubuntu 20.04 (not tested on 22.04)
- Azure CLI
- go 

## Setup
Edit environment variables in env.sh, and login into your azure subscrption. 
```
az login
az account set --subscription <YOUR_SUBSCRPTION_NAME>
```
Install the latest version of confidential computing extension for Azure CLI. 
```
az extension add 
```
## Build inferencing service
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
cd models
./fetch_models.sh
```

### Sign and Encrypt Models
Use the following script to sign and encrypt models using fresh keys. The keys are stored locally. 
```
./sign_and_encrypt_models.sh
```

### Upload models
Create a resource group, storage account and blob storage containers to store your models. This is a one time step.
```
./create_storage_container.sh
```
Upload encrypt model to storage container. 
```
./upload_encrypted_models.sh
```

### Provision keys to Azure Key Vault
```
./import_keys.sh
```
## Service Deployment

```
cd ../deployment
./deploy.sh
```
## Client Setup

## Run Inferencing Requests