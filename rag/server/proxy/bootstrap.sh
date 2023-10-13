#! /bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Generate self-signed certificate
mkdir keys
mkdir certs
openssl req -x509 -newkey rsa:2048 -keyout keys/server-key.pem -out certs/server-cert.pem -days 100 -nodes -subj '/CN=envoy-server'

# Extract sha256 hash of the certificate and format it
export CERTIFICATE_HASH=$(openssl x509 -noout -sha256 -fingerprint -in certs/server-cert.pem | cut -f2 -d "=" |  sed -e "s/://g" | tr '[:upper:]' '[:lower:]')

echo "Certficate hash $CERTIFICATE_HASH"

# Generate attestation token 
echo "Generating attestation token..."
sudo ./confidential-computing-cvm-guest-attestation/cvm-attestation-sample-app/AttestationClient -n $CERTIFICATE_HASH -o token > ./attestation-token.txt
cat attestation-token.txt

# Obtain token validation certificate
MAA_OPENID_RESPONSE=`curl -X GET https://$MAA_ENDPOINT/.well-known/openid-configuration`
JWKS_URI=`echo $MAA_OPENID_RESPONSE | jq -r .jwks_uri`
JWKS_RESPONSE=`curl -X GET $JWKS_URI`
MAA_CERTIFICATE_CONTENT=`echo $JWKS_RESPONSE | jq -r .keys[0].x5c[0] | sed 's/-----.* CERTIFICATE-----//g'  | fold -w 63`
echo "-----BEGIN CERTIFICATE-----" > attestation-service-cert.pem
echo ${MAA_CERTIFICATE_CONTENT} >> attestation-service-cert.pem
echo "-----END CERTIFICATE-----" >> attestation-service-cert.pem
openssl x509 -pubkey -noout -in attestation-service-cert.pem > attestation-service-key.pem

envoy -c proxy-config.yaml

