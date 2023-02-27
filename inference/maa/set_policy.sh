AZURE_MAA_ENDPOINT=`az attestation show --name $AZURE_MAA_CUSTOM_RESOURCE_NAME --resource-group $AZURE_RESOURCE_GROUP --query attestUri --output tsv | awk '{split($0,a,"//"); print a[2]}'`
MAA_POLICY_URI="https://$AZURE_MAA_ENDPOINT/policies/SevSnpVm?api-version=2022-08-01"
BEARER_TOKEN=`az account get-access-token --resource https://attest.azure.net --query accessToken --output tsv`
POLICY=`cat policy.jws`

curl -X PUT -H "Authorization:Bearer $BEARER_TOKEN" -H "Content-Type: text/plain" -d "$POLICY" "$MAA_POLICY_URI"