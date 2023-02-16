# Confidential Inference

This sample demonstrates Confidential Inferencing using Confidential Containers on ACI. 

## Prerequisites
- Azure subscription
- Azure Key Vault mHSM instance
- Ubuntu 20.04 (not tested on 22.04)
- Azure CLI
- go 
- jq

## Setup
Edit environment variables in env.sh. The AZURE_MSHM_ENDPOINT must point to an AKV mHSM instance where you have HSM Crypto User and Managed HSM Crypto Officer roles assigned. Activate the env.sh so that the environment variables are made available.

```
source env.sh
```

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
az acr login --name $CONTAINER_REGISTRY
./push_containers.sh
```

## Model Preparation
Place the models you would like to serve under the ```models/model_repository``` folder. You can use the following script to fetch samples models.
```
cd ../models
./fetch_models.sh
```
### Sign Models
Use the following script to sign models using fresh signing keys. 
```
./sign_models.sh
```
### Generate and Provision encryption keys to Azure Key Vault
Use the following script to sample a fresh encryption key. The encryption key will be stored under `modelkey.bin`. In the process, this script generates the policy which encodes the public signing key (from the previous step) as a command attribute for the inference server container. The user can specify the type of key that will be imported. For AKV key vaults, the only supported type is `RSA-HSM`. Because the models are encrypted using octet/symmetric keys, if the imported key is an `RSA-HSM` key, the tool derives an octet/symmetric key using the RSA private exponent `D`, a salt and a label. The user may pass the salt as a command attribute to the script.
```
./import_key.sh [-t <oct | oct-HSM | RSA | RSA-HSM>] [-s <salt_for_key_derivation_in_hexstring>]
```
### Encrypt Models
Use the following script to encrypt models using the `modelkey.bin` output from previous stage.
```
./encrypt_models.sh
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

## Service Deployment
```
cd ../deployment/confidential-aci
./deploy.sh
```
## Client Setup

## Run Inferencing Requests