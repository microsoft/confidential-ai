ACCOUNT_KEY=$(az storage account keys list --account-name $AZURE_STORAGE_ACCOUNT_NAME --only-show-errors | jq -r .[0].value)

az storage blob upload \
  --account-name $AZURE_STORAGE_ACCOUNT_NAME \
  --container $AZURE_STORAGE_CONTAINER_NAME \
  --file model.img \
  --name model.img \
  --type page \
  --overwrite \
  --account-key $ACCOUNT_KEY
