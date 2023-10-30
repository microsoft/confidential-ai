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

# Get SNP report 
echo "Fetching full SNP report..."
sudo tpm2_nvread -C o 0x01400001 > snp_report.bin
echo "Extracting guest report..."
dd skip=32 bs=1 count=1184 if=./snp_report.bin of=./guest_report.bin

# Extract HWID
export HWID=`xxd -ps -u -s 448 -c 64 snp_report.bin | head -1`

# Get cert chain
curl "https://kdsintf.amd.com/vcek/v1/Genoa/$HWID?ucodeSPL=22&snpSPL=11&teeSPL=0&blSPL=7" --output vcek.crt
openssl x509 -inform der -in vcek.crt -out vcek-leaf.pem
curl "https://kdsintf.amd.com/vcek/v1/Genoa/cert_chain" > genoa.pem
cat vcek-leaf.pem genoa.pem > vcek.pem

# Construct MAA request
base64url::encode () { base64 -w0 | tr '+/' '-_' | tr -d '='; }
base64url::decode () { awk '{ if (length($0) % 4 == 3) print $0"="; else if (length($0) % 4 == 2) print $0"=="; else print $0; }' | tr -- '-_' '+/' | base64 -d; }

export VCEK_CERT_CHAIN=`cat vcek.pem | base64url::encode`
export GUEST_REPORT=`cat guest_report.bin | base64url::encode`
export REPORT=`echo {} | jq '.SnpReport=env.GUEST_REPORT' | jq '.VcekCertChain=env.VCEK_CERT_CHAIN'`
export ENCODED_REPORT=`echo $REPORT | base64 -w0`
echo {} | jq '.report=env.ENCODED_REPORT' | jq '.nonce=env.CERTIFICATE_HASH' > request_body.json

# Request token from MAA
curl \
  --header "Content-Type: application/json" \
  --request POST \
  --data @request_body.json \
  "https://$MAA_ENDPOINT/attest/SevSnpVm?tee=SevSnpVm&api-version=2020-10-01" --output token.json

echo "MAA response"
echo `cat token.json`

jq -r .token token.json > attestation-token.txt

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

