#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

if [[ "$1" == "--sas" ]]; then 
  end=`date -u -d "600 minutes" '+%Y-%m-%dT%H:%MZ'`
  MODEL_SAS_TOKEN=$(az storage blob generate-sas --account-name $AZURE_STORAGE_ACCOUNT_NAME --container-name $AZURE_STORAGE_CONTAINER_NAME --permissions r --name model.img --expiry $end --only-show-errors) 
  export MODEL_SAS_TOKEN="$(echo -n $MODEL_SAS_TOKEN | tr -d \")"
  export MODEL_SAS_TOKEN="?$MODEL_SAS_TOKEN"
  export URL_PRIVATE="false"
else
  export URL_PRIVATE="true"  
fi

# Retrieve the key type
export AZURE_AKV_KEY_TYPE=$(cat /tmp/importkey-config.json | jq '.key.kty' | sed 's/\"//g')
# Retrieve the salt and label. Needed for RSA-HSM keys
export AZURE_AKV_KEY_DERIVATION_SALT=$(cat /tmp/importkey-config.json | jq '.key_derivation.salt' | sed 's/\"//g')
export AZURE_AKV_KEY_DERIVATION_LABEL=$(cat /tmp/importkey-config.json | jq '.key_derivation.label' | sed 's/\"//g')

if [[ "$AZURE_MAA_ENDPOINT" == "" ]]; then
  export AZURE_MAA_ENDPOINT=`az attestation show --name $AZURE_MAA_CUSTOM_RESOURCE_NAME --resource-group $AZURE_RESOURCE_GROUP --query attestUri --output tsv | awk '{split($0,a,"//"); print a[2]}'`
fi

TMP=$(jq . encrypted-filesystem-config-template.json)
TMP=`echo $TMP | \
  jq '.azure_filesystems[0].azure_url = "https://" + env.AZURE_STORAGE_ACCOUNT_NAME + ".blob.core.windows.net/" + env.AZURE_STORAGE_CONTAINER_NAME + "/model.img" + env.MODEL_SAS_TOKEN' | \
  jq '.azure_filesystems[0].mount_point = "/mnt/remote/models"' | \
  jq '.azure_filesystems[0].key.kid = "ModelFilesystemEncryptionKey"' | \
  jq '.azure_filesystems[0].key.kty = env.AZURE_AKV_KEY_TYPE' | \
  jq '.azure_filesystems[0].key.authority.endpoint = env.AZURE_MAA_ENDPOINT' | \
  jq '.azure_filesystems[0].key.akv.endpoint = env.AZURE_AKV_RESOURCE_ENDPOINT' | \
  jq '.azure_filesystems[0].key_derivation.salt = env.AZURE_AKV_KEY_DERIVATION_SALT' | \
  jq '.azure_filesystems[0].key_derivation.label = env.AZURE_AKV_KEY_DERIVATION_LABEL'`

if [[ "$URL_PRIVATE" == "false" ]]; then
  TMP=`echo $TMP | jq '.azure_filesystems[0].azure_url_private = false'`
fi

echo $TMP
