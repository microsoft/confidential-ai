# Confidential Inference

This sample demonstrates Confidential Inferencing using Confidential Containers on ACI. The architecture and its threat model is presented [here.](docs/arch.md)


## Prerequisites
- Azure subscription
- Azure Key Vault instance or Key Vault mHSM instance (for enhanced security)
- Ubuntu 20.04 (not tested on 22.04)
- Azure CLI
- go 
- jq
- Python 3.6.9 and pip

## Setup
Clone this repository, including sub-modules. 
```
git clone --recursive https://github.com/microsoft/confidential-ai
```

Edit environment variables in env.sh. The `AZURE_AKV_RESOURCE_ENDPOINT` must point to either (a) a managed HSM instance where you have `Managed HSM Crypto User` and `Managed HSM Crypto Officer` roles assigned or (b) a key vault instance where you have `Key Vault Crypto User` and `Key Vault Crypto Officer roles` assigned.

Activate the env.sh so that the environment variables are made available.
```
source env.sh
```

Next, login into your azure subscrption. 
```
az login
az account set --subscription <YOUR_SUBSCRPTION_NAME>
```

Remove previously deployed version confidential computing extension for Azure CLI. 
```
az extension remove --name confcom
```

Install the latest version of confidential computing extension. 
```
az extension add --source https://acccliazext.blob.core.windows.net/confcom/confcom-0.2.10-py3-none-any.whl -y
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
On the client, we will use the Triton client library and sample applications to demonstrate how to setup secure and attested communication between a confidential container group and a client application. For attesting the server, we will use an enlightened client-side HTTP proxy based on Envoy, which supports attested TLS. 

First build the envory proxy using the following script. 

```
cd ../ci
./build_client.sh
```

This will build a container image called ```inference-client-proxy```. 

Next, we will generate a client-side attestation policy. This is a set of claims (expressed as a json object) that must hold in the attestation token from the service during attested TLS. For example, the following attestation policy specifies a number of claims including a specific ```hostdata``` value. 

```json
{
  "x-ms-attestation-type": "sevsnpvm",
  "x-ms-compliance-status": "azure-compliant-uvm",
  "x-ms-sevsnpvm-bootloader-svn": 3,
  "x-ms-sevsnpvm-hostdata": "16281d25aa3713ca0285e1161430c80b159daa54681063d6efc35edb53ac448e",
  "x-ms-sevsnpvm-is-debuggable": false
}
```

Alternatively, if policy enforcement has been delegated to MAA, clients can be configured with the following borader policy. 
```json
{
  "x-ms-attestation-type": "sevsnpvm",
  "x-ms-compliance-status": "azure-compliant-uvm",
  "x-ms-sevsnpvm-bootloader-svn": 3,
  "x-ms-policy-signer": {
    "kty": "RSA",
    "x5c": [ 
      "MIIDpjC..."
    ]
  },
  "x-ms-sevsnpvm-is-debuggable": false
}
```

Use the following script to generate a suitable attestation policy.
```
cd ../client
./generate_attestation_policy.sh [--signer|--hostdata]
``` 

Now, deploy the proxy where it is reachable from all your clients. For example, you can use docker to deploy the proxy locally. 

```
docker run -it --privileged --network host --env MAA_ENDPOINT=$AZURE_MAA_ENDPOINT --env ATTESTATION_POLICY=$ATTESTATION_POLICY inference-client-proxy /bin/bash -c ./bootstrap.sh
```
The proxy will listen for incoming requests on port 15001.

## Run Inference Requests
Pull the triton client container image.

```
docker pull nvcr.io/nvidia/tritonserver:22.05-py3-sdk
```

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

If all goes well and the inferencing service meets the configured attestation policy, you should receive an inference response as follows.
```
Request 0, batch size 1
Image '../../images/mug.jpg':
    15.349563 (504) = COFFEE MUG
    13.227461 (968) = CUP
    10.424893 (505) = COFFEEPOT
```
