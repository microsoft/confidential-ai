#!/bin/bash
end=`date -u -d "600 minutes" '+%Y-%m-%dT%H:%MZ'`
MODEL_SAS_TOKEN=$(az storage blob generate-sas --account-name $AZURE_STORAGE_ACCOUNT_NAME --container-name $AZURE_STORAGE_CONTAINER_NAME --permissions r --name model.img --expiry $end --only-show-errors) 
export MODEL_SAS_TOKEN="$(echo -n $MODEL_SAS_TOKEN | tr -d \")"
export MODEL_SAS_TOKEN="?$MODEL_SAS_TOKEN"

if [[ "$AZURE_AKV_RESOURCE_ENDPOINT" == *".vault.azure.net" ]]; then
  AKV_TOKEN=$(az account get-access-token --resource https://vault.azure.net)
  export AKV_TOKEN=$(echo $AKV_TOKEN | jq -r .accessToken)    
elif [[ "$AZURE_AKV_RESOURCE_ENDPOINT" == *".managedhsm.azure.net" ]]; then
  AKV_TOKEN=$(az account get-access-token --resource https://managedhsm.azure.net)
  export AKV_TOKEN=$(echo $AKV_TOKEN | jq -r .accessToken)  
fi

export AZURE_AKV_KEY_TYPE=$(cat /tmp/importkey-config.json | jq '.key.kty' | sed 's/\"//g')
export AZURE_AKV_KEY_DERIVATION_SALT=$(cat /tmp/importkey-config.json | jq '.key_derivation.salt' | sed 's/\"//g')
export AZURE_AKV_KEY_DERIVATION_LABEL=$(cat /tmp/importkey-config.json | jq '.key_derivation.label' | sed 's/\"//g')

TMP=$(jq . encrypted-filesystem-config-template.json)

TMP=`echo $TMP | \
  jq '.azure_filesystems[0].azure_url = "https://" + env.AZURE_STORAGE_ACCOUNT_NAME + ".blob.core.windows.net/" + env.AZURE_STORAGE_CONTAINER_NAME + "/model.img" + env.MODEL_SAS_TOKEN' | \
  jq '.azure_filesystems[0].mount_point = "/mnt/remote/models"' | \
  jq '.azure_filesystems[0].key.kid = "ModelFilesystemEncryptionKey"' | \
  jq '.azure_filesystems[0].key.kty = env.AZURE_AKV_KEY_TYPE' | \
  jq '.azure_filesystems[0].key.akv.endpoint = env.AZURE_AKV_RESOURCE_ENDPOINT' | \
  jq '.azure_filesystems[0].key.akv.bearer_token = env.AKV_TOKEN' | \
  jq '.azure_filesystems[0].key_derivation.salt = env.AZURE_AKV_KEY_DERIVATION_SALT' | \
  jq '.azure_filesystems[0].key_derivation.label = env.AZURE_AKV_KEY_DERIVATION_LABEL'`
echo $TMP