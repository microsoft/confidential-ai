# Confidential Inference

This sample demonstrates Confidential Inferencing using Confidential Containers on ACI. 

## Prerequisites
- Azure subscription
- Azure Key Vault mHSM instance
- Ubuntu 20.04 (not tested on 22.04)
- Azure CLI
- go 

## Setup
Edit environment variables in env.sh. The AZURE_MSHM_ENDPOINT must point to an AKV mHSM instance where you have HSM Crypto User and Managed HSM Crypto Officer roles assigned. 

Next, login into your azure subscrption. 
```
az login
az account set --subscription <YOUR_SUBSCRPTION_NAME>
```
Install the latest version of confidential computing extension for Azure CLI. 
```
az extension add --source https://acccliazext.blob.core.windows.net/confcom/confcom-0.2.9-py3-none-any.whl -y
```
## Build inferencing service
Build server-side containers 
```
cd ci
./build_server.sh
```

Push containers to container registry
```
az acr login $CONTAINER_REGISTRY
./push_containers.sh
```

## Model Preparation
Place the models you would like to serve under the ```models/model_repository``` folder. You can use the following script to fetch samples models.
```
cd ../models
./fetch_models.sh
```

### Sign and Encrypt Models
Use the following script to sign and encrypt models using fresh keys. 
```
./sign_and_encrypt_models.sh
```

### Upload models
Create a resource group, storage account and blob storage containers to store your encrypted models.
```
./create_storage_container.sh
```
Upload encrypted models to storage container. 
```
./upload_encrypted_models.sh
```

### Provision keys to Azure Key Vault
```
./import_key.sh
```
## Service Deployment

```
cd ../deployment
./deploy.sh
```
## Client Setup

## Run Inferencing Requests