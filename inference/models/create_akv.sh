#!/bin/bash

echo $AZURE_AKV_RESOURCE_ENDPOINT
echo $AZURE_RESOURCE_GROUP

if [[ "$AZURE_AKV_RESOURCE_ENDPOINT" == *".vault.azure.net" ]]; then 
    AZURE_AKV_RESOURCE_NAME=`echo $AZURE_AKV_RESOURCE_ENDPOINT | awk '{split($0,a,"."); print a[1]}'`
    az keyvault create --name $AZURE_AKV_RESOURCE_NAME --resource-group $AZURE_RESOURCE_GROUP --sku "Premium"
else
    echo "Automated creation of key vaults is supported only for vaults"
fi
