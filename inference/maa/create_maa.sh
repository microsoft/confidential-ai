#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

rm cert.raw
rm cert.pem

# Creates an RSA signing key and exports the public key's certificate
# in PEM format

go run main.go -p /tmp/maa-policy.in -c

export policyCertX509=`cat cert.raw`

echo Generating parameters for MAA deployment...
TMP=$(jq '.attestationProviderName.value = env.AZURE_MAA_CUSTOM_RESOURCE_NAME' maa-parameters-template.json)
TMP=`echo $TMP | jq '.policySigningCertificates.value = env.policyCertX509'`

echo $TMP > /tmp/maa-parameters.json

az deployment group create \
  --resource-group $AZURE_RESOURCE_GROUP \
  --template-file arm-template.json \
  --parameters @/tmp/maa-parameters.json
