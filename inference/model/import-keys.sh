envsubst < policy-in-template.json > /tmp/policy-in.json
export CCE_POLICY=$(az confcom acipolicygen -i /tmp/policy-in.json)
export CCE_POLICY_HASH=$($TOOLS_HOME/securitypolicydigest -p $CCE_POLICY | tail --bytes=64)
echo "Training container policy hash $CCE_POLICY_HASH"

export BEARER_TOKEN=$(az account get-access-token --resource https://managedhsm.azure.net | jq -r .accessToken)

CONFIG=$(jq '.release_policy.anyOf[0].allOf[0].equals = env.CCE_POLICY_HASH' importkey-config-template.json)
CONFIG=$(echo $CONFIG | jq '.key.kid = "ICMRFilesystemEncryptionKey"')
CONFIG=$(echo $CONFIG | jq '.key.mhsm.endpoint = env.AZURE_ICMR_MHSM_ENDPOINT')
CONFIG=$(echo $CONFIG | jq '.key.mhsm.bearer_token = env.BEARER_TOKEN')
echo $CONFIG > /tmp/importkey-config.json
ICMR_KEY=$(xxd -ps -c 32 icmrkey.bin | head -1)
echo "Importing ICMR key with key release policy"
jq '.key.mhsm.bearer_token = "REDACTED"' /tmp/importkey-config.json
$TOOLS_HOME/importkey -c /tmp/importkey-config.json -kh $ICMR_KEY

CONFIG=$(jq '.release_policy.anyOf[0].allOf[0].equals = env.CCE_POLICY_HASH' importkey-config-template.json)
CONFIG=$(echo $CONFIG | jq '.key.kid = "COWINFilesystemEncryptionKey"')
CONFIG=$(echo $CONFIG | jq '.key.mhsm.endpoint = env.AZURE_COWIN_MHSM_ENDPOINT')
CONFIG=$(echo $CONFIG | jq '.key.mhsm.bearer_token = env.BEARER_TOKEN')
echo $CONFIG > /tmp/importkey-config.json
COWIN_KEY=$(xxd -ps -c 32 cowinkey.bin | head -1)
echo
echo "Importing COWIN key..."
$TOOLS_HOME/importkey -c /tmp/importkey-config.json -kh $COWIN_KEY

CONFIG=$(jq '.release_policy.anyOf[0].allOf[0].equals = env.CCE_POLICY_HASH' importkey-config-template.json)
CONFIG=$(echo $CONFIG | jq '.key.kid = "IndexFilesystemEncryptionKey"')
CONFIG=$(echo $CONFIG | jq '.key.mhsm.endpoint = env.AZURE_INDEX_MHSM_ENDPOINT')
CONFIG=$(echo $CONFIG | jq '.key.mhsm.bearer_token = env.BEARER_TOKEN')
echo
echo $CONFIG > /tmp/importkey-config.json
INDEX_KEY=$(xxd -ps -c 32 indexkey.bin | head -1)
echo "Importing index key..."
$TOOLS_HOME/importkey -c /tmp/importkey-config.json -kh $INDEX_KEY

rm /tmp/importkey-config.json
rm /tmp/policy-in.json