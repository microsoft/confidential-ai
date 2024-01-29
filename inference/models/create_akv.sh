#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo $AZURE_AKV_RESOURCE_ENDPOINT
echo $AZURE_RESOURCE_GROUP

if [[ "$AZURE_AKV_RESOURCE_ENDPOINT" == *".vault.azure.net" ]]; then 
    # Create Azure key vault with RBAC authorization
    AZURE_AKV_RESOURCE_NAME=`echo $AZURE_AKV_RESOURCE_ENDPOINT | awk '{split($0,a,"."); print a[1]}'`
    az keyvault create --name $AZURE_AKV_RESOURCE_NAME --resource-group $AZURE_RESOURCE_GROUP --sku "Premium" --enable-rbac-authorization
    # Assign RBAC roles to the resource owner so they can import keys
    AKV_SCOPE=`az keyvault show --name $AZURE_AKV_RESOURCE_NAME --query id --output tsv`    
    az role assignment create --role "Key Vault Crypto Officer" --assignee `az account show --query user.name --output tsv` --scope $AKV_SCOPE
    az role assignment create --role "Key Vault Crypto User" --assignee `az account show --query user.name --output tsv` --scope $AKV_SCOPE
else
    echo "Automated creation of key vaults is supported only for vaults"
fi
