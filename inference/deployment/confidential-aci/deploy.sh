echo Computing CCE policy...
envsubst < policy-in-template.json > /tmp/policy-in.json
export CCE_POLICY=$(az confcom acipolicygen -i /tmp/policy-in.json)

echo Generating encrypted file system information...
export ENCRYPTED_FILESYSTEM_INFORMATION=`./generate-encrypted-filesystem-info.sh | base64 --wrap=0`

echo Generating parameters for ACI deployment...
TMP=$(jq '.containerRegistry.value = env.CONTAINER_REGISTRY' aci-parameters-template.json)
TMP=`echo $TMP | jq '.ccePolicy.value = env.CCE_POLICY'`
TMP=`echo $TMP | jq '.EncfsSideCarArgs.value = env.ENCRYPTED_FILESYSTEM_INFORMATION'`
echo $TMP > /tmp/aci-parameters.json

az deployment group create \
  --resource-group $AZURE_TRAINING_RESOURCE_GROUP \
  --template-file arm-template.json \
  --parameters @/tmp/aci-parameters.json

rm /tmp/aci-parameters.json
rm /tmp/policy-in.json

echo Deployment complete. 
