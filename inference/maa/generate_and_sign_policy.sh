#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

while getopts ":k:" options; do
    case $options in
        k)rsaKeyFile=$OPTARG;;    
    esac
done

TOOLS_HOME=${PWD}/../external/confidential-sidecar-containers/tools

envsubst < ../policy/policy-in-template.json > /tmp/policy-in.json
export CCE_POLICY=$(az confcom acipolicygen -i /tmp/policy-in.json)

pushd .
cd $TOOLS_HOME/securitypolicydigest
export CCE_POLICY_HASH=$(go run main.go -p $CCE_POLICY | tail --bytes=65)
popd
echo "Inference server container policy hash $CCE_POLICY_HASH"

envsubst < policy.in.template > /tmp/maa-policy.in

rm policy.jws

if [ -f "$rsaKeyFile" ]; then
    go run main.go -p /tmp/maa-policy.in -k $rsaKeyFile
else
    echo "Passing private_key.pem key file as default"
    go run main.go -p /tmp/maa-policy.in -k private_key.pem
fi
