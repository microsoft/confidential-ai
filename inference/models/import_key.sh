#!/bin/bash

while getopts ":t:s:" options; do
    case $options in
        t)kty=$OPTARG;;
        s)salt=$OPTARG;;           
    esac
done

TOOLS_HOME=${PWD}/../external/confidential-sidecar-containers/tools

# Generate container security policy to be bound to the key
export MODEL_SIGNING_KEY=`cat signing_public.pem | base64 -w0`
envsubst < ../policy/policy-in-template.json > /tmp/policy-in.json
export CCE_POLICY=$(az confcom acipolicygen -i /tmp/policy-in.json)

pushd .
cd $TOOLS_HOME/securitypolicydigest
export CCE_POLICY_HASH=$(go run main.go -p $CCE_POLICY | tail --bytes=64)
popd
echo "Inference server container policy hash $CCE_POLICY_HASH"

# Set the key type environment variable
if [ "$kty" = *"RSA" ]; then
    export AZURE_AKV_KEY_TYPE="RSA-HSM"
elif [ "$kty" = *"oct" ]; then
    export AZURE_AKV_KEY_TYPE="oct-HSM"
fi

# Generate key import configuration. Default AKV resource type is managed hsm
if [[ "$AZURE_AKV_RESOURCE_ENDPOINT" == *".vault.azure.net" ]]; then
    export BEARER_TOKEN=$(az account get-access-token --resource https://vault.azure.net | jq -r .accessToken)
    echo "Importing keys to AKV key vaults can be only of type RSA-HSM"
    export AZURE_AKV_KEY_TYPE="RSA-HSM"
elif [[ "$AZURE_AKV_RESOURCE_ENDPOINT" == *".managedhsm.azure.net" ]]; then
    export BEARER_TOKEN=$(az account get-access-token --resource https://managedhsm.azure.net | jq -r .accessToken)    
fi

# For RSA-HSM keys, we need to set a salt and label which will be used in the symmetric key derivation
if [ "$AZURE_AKV_KEY_TYPE" = "RSA-HSM" ]; then    
    if [[ -z "$salt" ]]; then
        dd if=/dev/random of="salt_modelkey.bin" count=1 bs=32
        export AZURE_AKV_KEY_DERIVATION_SALT=$(python hexstring.py salt_modelkey.bin | sed "s/'//g" | sed "1s/^.//") 
    else
        export AZURE_AKV_KEY_DERIVATION_SALT=$salt
    fi

    export AZURE_AKV_KEY_DERIVATION_LABEL="Model Encryption Key"
fi

CONFIG=$(jq '.claims[0][0].equals = env.CCE_POLICY_HASH' importkey-config-template.json)
CONFIG=$(echo $CONFIG | jq '.key.kid = "ModelFilesystemEncryptionKey"')
CONFIG=$(echo $CONFIG | jq '.key.kty = env.AZURE_AKV_KEY_TYPE')
CONFIG=$(echo $CONFIG | jq '.key_derivation.salt = env.AZURE_AKV_KEY_DERIVATION_SALT')
CONFIG=$(echo $CONFIG | jq '.key_derivation.label = env.AZURE_AKV_KEY_DERIVATION_LABEL')
CONFIG=$(echo $CONFIG | jq '.key.akv.endpoint = env.AZURE_AKV_RESOURCE_ENDPOINT')
CONFIG=$(echo $CONFIG | jq '.key.akv.bearer_token = env.BEARER_TOKEN')
echo $CONFIG > /tmp/importkey-config.json

# Import key into key vault
echo "Importing model key..."
pushd .
cd $TOOLS_HOME/importkey
go run main.go -c /tmp/importkey-config.json -out
popd
mv $TOOLS_HOME/importkey/keyfile.bin modelkey.bin
if [[ "$vaultType" = "vault" ]]; then
    mv $TOOLS_HOME/importkey/private_key.pem rsa_material_modelkey.pem    
fi

