#/bin/bash
if [[ "$1" == "--hostdata" ]]; then
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

  TMP=$(jq . attestation-policy-template-hostdata.json)
  TMP=$(echo $TMP | jq '."x-ms-sevsnpvm-hostdata" = env.CCE_POLICY_HASH')
  echo "Attestation policy: $TMP"

  export ATTESTATION_POLICY=$(echo $TMP | base64 -w0)
elif [[ "$1" == "--policysigner" ]]; then
  if [[ ! -r "../maa/cert.raw" ]]; then
    echo "MAA policy signer certificate not found."
    exit 1
  fi
  export POLICY_SIGNER=$(cat ../maa/cert.raw)
  TMP=$(jq . attestation-policy-template-policysigner.json)
  TMP=$(echo $TMP | jq '."x-ms-policy-signer".x5c[0] = env.POLICY_SIGNER')
  echo "Attestation policy: $TMP"
  export ATTESTATION_POLICY=$(echo $TMP | base64 -w0)
else 
  echo "Unsupported attestation policy type."
fi