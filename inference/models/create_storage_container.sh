az storage account create \
    --resource-group $AZURE_RESOURCE_GROUP \
    --name $AZURE_STORAGE_ACCOUNT_NAME

az storage container create \
    --resource-group $AZURE_RESOURCE_GROUP \
    --account-name $AZURE_STORAGE_ACCOUNT_NAME \
    --name $AZURE_STORAGE_CONTAINER_NAME 
