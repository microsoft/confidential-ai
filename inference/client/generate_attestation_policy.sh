#/bin/bash

echo Computing CCE policy...
export MODEL_SIGNING_KEY=`cat ../models/signing_public.pem | base64 -w0`
envsubst < ../policy/policy-in-template.json > /tmp/policy-in.json
CCE_POLICY=$(az confcom acipolicygen -i /tmp/policy-in.json)

TOOLS_HOME=${PWD}/../external/confidential-sidecar-containers/tools

pushd .
cd $TOOLS_HOME/securitypolicydigest
export CCE_POLICY_HASH=$(go run main.go -p $CCE_POLICY | tail --bytes=64)
popd
echo "Inference server container policy hash $CCE_POLICY_HASH"

if [[ "$1" == "--hostdata" ]]; then
  TMP=$(jq . attestation-policy-template-hostdata.json)
  TMP=$(echo $TMP | jq '."x-ms-sevsnpvm-hostdata" = env.CCE_POLICY_HASH')
  echo "Attestation policy: $TMP"
  export ATTESTATION_POLICY=$(echo $TMP | base64 -w0)
fi
