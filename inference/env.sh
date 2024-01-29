# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Name of the container registry where container images will be deployed
export CONTAINER_REGISTRY=

# Credentials to access the registry
export CONTAINER_REGISTRY_USERNAME=
export CONTAINER_REGISTRY_PASSWORD=

# Name and location of resource group where all resources will be created
export AZURE_RESOURCE_GROUP=
export AZURE_RESOURCE_GROUP_LOCATION=

# Name of user-assigned managed identity that container group will use to access resources
export AZURE_USER_ASSIGNED_IDENTITY=

# Name of storage account and blob container where encrypted models will be stored
export AZURE_STORAGE_ACCOUNT_NAME=
export AZURE_STORAGE_CONTAINER_NAME=

# URL of AKV instance (without the leading https://)
export AZURE_AKV_RESOURCE_ENDPOINT=

# URL of the MAA endpoint (without leading https://)
# Leave this empty if using policy delegation to custom MAA instance
export AZURE_MAA_ENDPOINT=

# Name of the custom MAA instance (required only if using policy delegation)
export AZURE_MAA_CUSTOM_RESOURCE_NAME=

# DNS name assigned to the container group
# Depending on the region where the container group is deployed, an appropriate suffix will be added
export DNS_NAME_LABEL=