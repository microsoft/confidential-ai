TOOLS_HOME=${PWD}/../external/confidential-sidecar-containers/tools

# Generate container security policy to be bound to the key
export MODEL_SIGNING_KEY=`cat signing_public.pem | base64 -w0`
envsubst < ../policy/policy-in-template.json > /tmp/policy-in.json
export CCE_POLICY=$(az confcom acipolicygen -i /tmp/policy-in.json)

pushd .
cd $TOOLS_HOME/securitypolicydigest
export CCE_POLICY_HASH=$(go run main.go -p $CCE_POLICY | tail --bytes=64)
popd
echo "Inference server container policy hash $CCE_POLICY_HASH"

# Generate key import configuration
export BEARER_TOKEN=$(az account get-access-token --resource https://managedhsm.azure.net | jq -r .accessToken)

CONFIG=$(jq '.claims[0][0].equals = env.CCE_POLICY_HASH' importkey-config-template.json)
CONFIG=$(echo $CONFIG | jq '.key.kid = "ModelFilesystemEncryptionKey"')
CONFIG=$(echo $CONFIG | jq '.key.mhsm.endpoint = env.AZURE_MHSM_ENDPOINT')
CONFIG=$(echo $CONFIG | jq '.key.mhsm.bearer_token = env.BEARER_TOKEN')
echo $CONFIG > /tmp/importkey-config.json
MODEL_KEY=$(xxd -ps -c 32 modelkey.bin | head -1)

# Import key into key vault
echo "Importing model key..."
pushd .
cd $TOOLS_HOME/importkey
go run main.go -c /tmp/importkey-config.json -kh $MODEL_KEY
popd
