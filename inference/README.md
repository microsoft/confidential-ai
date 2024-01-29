# Confidential Inference

This sample demonstrates confidential inferencing using Confidential Containers on ACI. With confidential containers on ACI, model developers and data owners can collaborate while protecting the intellectual property of the model developer and helping keep the data used for inferencing secure and private. This sample also showcases how clients can delegate the process of verifying trustworthiness of a confidential service to an external auditors, enabling the service to be seamlessly upgraded without disruption to clients. A more detailed description of the architecture and threat model can be found [here.](docs/arch.md)

## Prerequisites
- Azure subscription
- Azure Key Vault instance or Key Vault mHSM instance (for enhanced security)
- Ubuntu 20.04 (not tested on 22.04)
- Azure CLI
- go 
- jq
- Python 3.6.9 and pip

## Setup
Clone this repository including sub-modules. 
```
git clone --recursive https://github.com/microsoft/confidential-ai
```

Next, configure environment variables in ```env.sh```. The `AZURE_AKV_RESOURCE_ENDPOINT` must point to either (a) a managed HSM instance where you have `Managed HSM Crypto User` and `Managed HSM Crypto Officer` roles assigned or (b) a key vault instance where you have `Key Vault Crypto User` and `Key Vault Crypto Officer roles` assigned.

Next, run the script ```env.sh``` so that the environment variables are available .
```
source env.sh
```

Login into your azure subscription. 
```
az login
az account set --subscription <YOUR_SUBSCRPTION_NAME>
```

Install the latest version of confidential computing extension for ACI confidential containers. 
```
az extension add --name confcom
```

## Build inferencing service
Build server-side containers using the following script. 
```
cd ci
./build_server.sh
```

This script will build the following container images. 

1. Triton inference server.
2. Encrypted filesystem sidecar.
3. Enlightened envoy proxy supporting attested TLS.
4. Init container that configures iptables to route traffic through the envoy proxy. 

Push these containers to your container registry. 
```
az acr login --name $CONTAINER_REGISTRY
./push_containers.sh
```

## Model Preparation
Next, create a resource group under which all storage and compute resources will be created. This is a one time step. 
```
cd models
./create_resource_group.sh
```

Place the models you would like to serve under the ```models/model_repository``` folder. For example, you can use the following script to fetch the densenet ONNX model.
```
./fetch_models.sh
```
### Sign Models
Use the following script to sign models using fresh signing keys. This allows relying parties to attest to the model developer's identity before releasing their data for inferencing. 
```
./sign_models.sh
```
### Generate and provision model encryption key to Azure Key Vault
Create an Azure Key vault using the following script. If you need to create a managed HSM then you need to create it manually using the steps described [here](https://learn.microsoft.com/en-us/azure/key-vault/managed-hsm/overview).

```
./create_akv.sh
```

Next, use the following script to sample a fresh symmetric model encryption key (stored locally in the file `modelkey.bin`), and import the key into Azure Key Vault with a key release policy that allows the key to be released only to a correctly configured inferencing service running within a TEE. 

For AKV premium key vaults, the only supported type is `RSA-HSM`. In this case, the script derives an octet/symmetric key using the RSA private exponent `D`, a salt and a label. The user may pass the salt as a parameter to the script.
```
./import_key.sh [-t <oct | oct-HSM | RSA | RSA-HSM>] [-s <salt_for_key_derivation_in_hexstring>]
```

### Encrypt models
Use the following script to encrypt models and generate an encrypted filesystem image using the key generated in the previous.
```
./encrypt_models.sh
```
### Upload models
Create a storage account and blob storage containers to store your encrypted models.
```
./create_storage_container.sh
```

Upload encrypted models to storage container. 
```
./upload_encrypted_models.sh
```

## Custom MAA endpoint deployment
This is an optional step in case clients wish to delegate the verification of the service's TEE configuration to an external entity such as an auditor. 

Create a custom MAA instance (this is a one time step). 
```
cd maa
./create_maa.sh
```

The file ```policy.in.template``` contains a sample policy that can be enforced by MAA. Use the following script to generate and sign the policy using a fresh set of signing keys. In a more realistic setting, this step would be performed by an auditor using her keys after auditing the container security policy, and confirming that it meets the clients security requirements. 
```
./generate_and_sign_policy.sh
```

Next, set the attestation policy in the custom MAA instance. 
```
./set_policy.sh
```

Once the policy is configured, the MAA instance will only issue attestation tokens to service instances that meet the attestation policy. 

## Service Deployment
Use the following scripts to create a user-assigned managed identity that will be used by the container group to access resources such as Azure Key Vault and storage, and assign required permissions. 

```
cd deployment/confidential-aci
./create_identity.sh
./assign_permissions.sh
```

Use the following script to deploy the inferencing service to ACI. 

```
./deploy.sh
```
When the service is deployed, the encrypted storage sidecar will 

1. Fetch the encrypted filesystem containing the models from storage
2. Fetch an attestation token from MAA after presenting its attestation report. 
3. Fetch the model encryption keys from AKV using the attestation token. 
4. Decrypt the filesystem 

At this point, the triton container will detect the presence of the models and load them for serving client requests. 

## Client Setup
On the client-side, we will use the Triton client library and sample applications to demonstrate how to setup secure and attested communication between a inferencing service and a client application. Our sample will use an enlightened client-side HTTP proxy based on [Envoy](https://www.envoyproxy.io/), which supports [attested TLS](docs/arch.md). 

First, build the enlightened envoy proxy using the following script. 

```
cd ci
./build_client.sh
```

This will build a container image called ```inference-client-proxy```. 

Next, we will generate a client-side attestation policy. The client side policy is a set of claims (expressed as a json object) that must hold in the attestation token obtained from the service during the TLS handshake. For example, the following attestation policy specifies a number of claims including a specific ```hostdata``` value. 

```json
{
  "x-ms-attestation-type": "sevsnpvm",
  "x-ms-compliance-status": "azure-compliant-uvm",
  "x-ms-sevsnpvm-bootloader-svn": 3,
  "x-ms-sevsnpvm-hostdata": "[SHA256 hash digest of container security policy]",
  "x-ms-sevsnpvm-is-debuggable": false
}
```

Alternatively, the service supports delegation of attestation verification to an external party via MAA, the client can be configured with an attestation policy that only checks for the policy signer's key. This policy is more stable; it allows for the service to be upgraded (by updating the auditor's attestation policy) without disrupting the clients. 

```json
{
  "x-ms-attestation-type": "sevsnpvm",
  "x-ms-compliance-status": "azure-compliant-uvm",
  "x-ms-sevsnpvm-bootloader-svn": 3,
  "x-ms-policy-signer": {
    "kty": "RSA",
    "x5c": [ 
      "<Policy signing key>"
    ]
  },
  "x-ms-sevsnpvm-is-debuggable": false
}
```

Use the following script to generate a suitable attestation policy from templates provided in this source release.
```
cd client
source ./generate_attestation_policy.sh [--policysigner|--hostdata]
``` 
This script will set an environment variable ```$ATTESTATION_POLICY```. 

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

Next, run the triton client container image. 

```
docker run -it --network host nvcr.io/nvidia/tritonserver:22.05-py3-sdk
```
From the container, send an inference request using one of the sample applications. For example,

```
cd install/bin
http_proxy=http://127.0.0.1:15001 ./image_client -m densenet_onnx -c 3 -s INCEPTION ../../images/mug.jpg -u http://conf-inference.westeurope.azurecontainer.io:8000

```
Setting ```http_proxy``` redirects all HTTP traffic via the proxy, which establishes an attested TLS connection with the service. All subsequent requests and responses are encrypted with keys negotiatiated after the service has proven that it is running in a confidential container instance with a complaint UVM kernel and expected container security policy. 

If all goes well, you should receive an inference response as follows.
```
Request 0, batch size 1
Image '../../images/mug.jpg':
    15.349563 (504) = COFFEE MUG
    13.227461 (968) = CUP
    10.424893 (505) = COFFEEPOT
```

You can inspect the proxy logs to see the full attested TLS handshake. 
