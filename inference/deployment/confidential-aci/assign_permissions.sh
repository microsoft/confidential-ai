#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

## AKV 
echo $AZURE_AKV_RESOURCE_ENDPOINT
export AZURE_AKV_RESOURCE_NAME=`echo $AZURE_AKV_RESOURCE_ENDPOINT | awk '{split($0,a,"."); print a[1]}'`
export AZURE_ASSIGNED_IDENTITY_SPID=$(az identity show --name $AZURE_USER_ASSIGNED_IDENTITY --resource-group $AZURE_RESOURCE_GROUP --query principalId --output tsv)
if [[ "$AZURE_AKV_RESOURCE_ENDPOINT" == *".vault.azure.net" ]]; then 
  export AKV_SCOPE=`az keyvault show --name $AZURE_AKV_RESOURCE_NAME --query id --output tsv`
  echo "Assigning roles for $AZURE_AKV_RESOURCE_NAME to $AZURE_ASSIGNED_IDENTITY_SPID"  

  az role assignment create --role "Key Vault Crypto Officer" --assignee-object-id $AZURE_ASSIGNED_IDENTITY_SPID --assignee-principal-type ServicePrincipal --scope $AKV_SCOPE
  az role assignment create --role "Key Vault Crypto User" --assignee-object-id $AZURE_ASSIGNED_IDENTITY_SPID --assignee-principal-type ServicePrincipal --scope $AKV_SCOPE
elif [[ "$AZURE_AKV_RESOURCE_ENDPOINT" == *".managedhsm.azure.net" ]]; then
  echo "Assigning roles for $AZURE_AKV_RESOURCE_NAME to $AZURE_ASSIGNED_IDENTITY_SPID"

  az keyvault role assignment create --hsm-name $AZURE_AKV_RESOURCE_NAME --role "Managed HSM Crypto Officer" --assignee-object-id $AZURE_ASSIGNED_IDENTITY_SPID --assignee-principal-type ServicePrincipal --scope /keys
  az keyvault role assignment create --hsm-name $AZURE_AKV_RESOURCE_NAME --role "Managed HSM Crypto User" --assignee-object-id $AZURE_ASSIGNED_IDENTITY_SPID --assignee-principal-type ServicePrincipal  --scope /keys  
fi

## Storage container
export SUBSCRIPTION_ID=`az account show --query id --output tsv`
export AZURE_STORAGE_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$AZURE_STORAGE_ACCOUNT_NAME/blobServices/default/containers/$AZURE_STORAGE_CONTAINER_NAME"
echo $AZURE_STORAGE_SCOPE
az role assignment create --role "Storage Blob Data Reader" --assignee-object-id $AZURE_ASSIGNED_IDENTITY_SPID --assignee-principal-type ServicePrincipal --scope "$AZURE_STORAGE_SCOPE"
az role assignment create --role "Reader" --assignee-object-id $AZURE_ASSIGNED_IDENTITY_SPID --assignee-principal-type ServicePrincipal --scope "$AZURE_STORAGE_SCOPE"