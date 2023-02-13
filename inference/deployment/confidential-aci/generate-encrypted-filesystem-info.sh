end=`date -u -d "600 minutes" '+%Y-%m-%dT%H:%MZ'`
MODEL_SAS_TOKEN=$(az storage blob generate-sas --account-name $AZURE_STORAGE_ACCOUNT_NAME --container-name $AZURE_STORAGE_CONTAINER_NAME --permissions r --name model.img --expiry $end --only-show-errors) 
export MODEL_SAS_TOKEN="$(echo -n $MODEL_SAS_TOKEN | tr -d \")"
export MODEL_SAS_TOKEN="?$MODEL_SAS_TOKEN"

MHSM_TOKEN=$(az account get-access-token --resource https://managedhsm.azure.net)
export MHSM_TOKEN=$(echo $MHSM_TOKEN | jq -r .accessToken)

TMP=$(jq . encrypted-filesystem-config-template.json)

TMP=`echo $TMP | \
  jq '.azure_filesystems[0].azure_url = "https://" + env.AZURE_STORAGE_ACCOUNT_NAME + ".blob.core.windows.net/" + env.AZURE_STORAGE_CONTAINER_NAME + "/model.img" + env.MODEL_SAS_TOKEN' | \
  jq '.azure_filesystems[0].mount_point = "/mnt/remote/models"' | \
  jq '.azure_filesystems[0].key.kid = "ModelFilesystemEncryptionKey"' | \
  jq '.azure_filesystems[0].key.mhsm.endpoint = env.AZURE_MHSM_ENDPOINT' | \
  jq '.azure_filesystems[0].key.mhsm.bearer_token = env.MHSM_TOKEN'`

echo $TMP