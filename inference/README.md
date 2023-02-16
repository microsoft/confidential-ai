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
Clone this repository, including sub-modules. 
```
git clone --recursive https://github.com/microsoft/confidential-ai
```

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
cd ../deployment/confidential-aci
./deploy.sh
```
## Client Setup
On the client, we will use the Triton client library  and sample applications to demonstrate how to setup secure and attested communication between a confidential container group and a client application. For attesting the server, we will use an enlightened client-side HTTP proxy based on Envoy, which supports an attested TLS protocol. 

First build the envory proxy using the following script. 

```
cd ../ci
./built_client.sh
```

This will build a container image called ```inference-client-proxy```. Deploy this container where it is reachable from all your clients. For example, you can use docker to deploy the proxy locally. 

```
docker run -it --privileged --network host --env MAA_ENDPOINT=sharedneu.neu.attest.azure.net inference-client-proxy /bin/bash -c ./bootstrap.sh
```
The proxy will listen for incoming requests on port 15001.

## Run Inference Requests
Run the triton client container image. 

```
docker run -it --network host nvcr.io/nvidia/tritonserver:22.05-py3-sdk
```
From the container, send an inference request using one of the sample applications as follows.

```
cd install/bin
http_proxy=http://127.0.0.1:15001 ./image_client -m densenet_onnx -c 3 -s INCEPTION ../../images/mug.jpg -u http://conf-inference.westeurope.azurecontainer.io:8000

```
Setting the ```http_proxy``` environment variable redirects all HTTP traffic via the proxy, which establishes an attested TLS connection with the server. All subsequent requests and responses are encrypted with keys negotiatiated after the server has proven that it is running in a confidential container instance with a complaint UVM kernel and expected container security policy. 

If all goes well, you should receive an inference response as follows.
```
Request 0, batch size 1
Image '../../images/mug.jpg':
    15.349563 (504) = COFFEE MUG
    13.227461 (968) = CUP
    10.424893 (505) = COFFEEPOT
```