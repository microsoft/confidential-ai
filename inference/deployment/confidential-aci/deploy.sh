#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

export MODEL_SIGNING_KEY=`cat ../../models/signing_public.pem | base64 -w0`

echo Computing CCE policy...
envsubst < ../../policy/policy-in-template.json > /tmp/policy-in.json
export CCE_POLICY=$(az confcom acipolicygen -i /tmp/policy-in.json)

echo Generating encrypted file system information...
export ENCRYPTED_FILESYSTEM_INFORMATION=`./generate-encrypted-filesystem-info.sh --sas | base64 --wrap=0`

SUBSCRIPTION_ID=`az account show | jq ".id" | sed "s/\"//g"`
export USER_ASSIGNED_IDENTITY_URI="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$AZURE_USER_ASSIGNED_IDENTITY"

if [[ "$AZURE_MAA_ENDPOINT" == "" ]]; then
  export AZURE_MAA_ENDPOINT=`az attestation show --name $AZURE_MAA_CUSTOM_RESOURCE_NAME --resource-group $AZURE_RESOURCE_GROUP --query attestUri --output tsv | awk '{split($0,a,"//"); print a[2]}'`
fi

echo Generating parameters for ACI deployment...
TMP=$(jq '.userAssignedIdentity.value = env.USER_ASSIGNED_IDENTITY_URI' aci-parameters-template.json)
TMP=`echo $TMP | jq '.containerRegistry.value = env.CONTAINER_REGISTRY'`
TMP=`echo $TMP | jq '.containerRegistryUsername.value = env.CONTAINER_REGISTRY_USERNAME'`
TMP=`echo $TMP | jq '.containerRegistryPassword.value = env.CONTAINER_REGISTRY_PASSWORD'`
TMP=`echo $TMP | jq '.ccePolicy.value = env.CCE_POLICY'`
TMP=`echo $TMP | jq '.modelSigningKey.value = env.MODEL_SIGNING_KEY'`
TMP=`echo $TMP | jq '.EncfsSideCarArgs.value = env.ENCRYPTED_FILESYSTEM_INFORMATION'`
TMP=`echo $TMP | jq '.MAAEndpoint.value = env.AZURE_MAA_ENDPOINT'`
TMP=`echo $TMP | jq '.dnsNameLabel.value = env.DNS_NAME_LABEL'`
echo $TMP > /tmp/aci-parameters.json

az deployment group create \
  --resource-group $AZURE_RESOURCE_GROUP \
  --template-file arm-template.json \
  --parameters @/tmp/aci-parameters.json

echo Deployment complete. 

