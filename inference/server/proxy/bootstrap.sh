#! /bin/bash
export SKR_PORT=${SKR_PORT:-8284} 
./wait-for-it.sh --timeout=100  --strict 127.0.0.1:${SKR_PORT} -- echo "SKR sidecar available"

# Generate self-signed certificate
mkdir keys
mkdir certs
openssl req -x509 -newkey rsa:2048 -keyout keys/server-key.pem -out certs/server-cert.pem -days 100 -nodes -subj '/CN=envoy-server'

# Extract sha256 hash of the certificate and format it
export CERTIFICATE_HASH=$(openssl x509 -noout -sha256 -fingerprint -in certs/server-cert.pem | cut -f2 -d "=" |  sed -e "s/://g" | tr '[:upper:]' '[:lower:]')

if [ -e "/dev/sev" ]; then
  # Generate a attestation token
  RUNTIME_DATA=`jq --null-input '{"certificate_hash" : env.CERTIFICATE_HASH }' | base64 --wrap=0`
  RESPONSE=`curl -X POST 127.0.0.1:${SKR_PORT}/attest/maa -H 'Content-Type: application/json' -d "{ \"maa_endpoint\": \"$MAA_ENDPOINT\", \"runtime_data\":  \"$RUNTIME_DATA\" }"`
  echo Response from MAA...$RESPONSE
  echo $RESPONSE | jq -r .token > attestation-token.txt

  # Obtain token validation certificate
  MAA_OPENID_RESPONSE=`curl -X GET https://$MAA_ENDPOINT/.well-known/openid-configuration`
  JWKS_URI=`echo $MAA_OPENID_RESPONSE | jq -r .jwks_uri`
  JWKS_RESPONSE=`curl -X GET $JWKS_URI`
  MAA_CERTIFICATE_CONTENT=`echo $JWKS_RESPONSE | jq -r .keys[0].x5c[0] | sed 's/-----.* CERTIFICATE-----//g'  | fold -w 63`
  echo "-----BEGIN CERTIFICATE-----" > attestation-service-cert.pem
  echo ${MAA_CERTIFICATE_CONTENT} >> attestation-service-cert.pem
  echo "-----END CERTIFICATE-----" >> attestation-service-cert.pem
  openssl x509 -pubkey -noout -in attestation-service-cert.pem > attestation-service-key.pem

  export CCR_SIDECAR_PORT=${CCR_SIDECAR_PORT:-8281} 
  cat ccr-proxy-config.yaml | envsubst '$CCR_SIDECAR_PORT' > /tmp/ccr-proxy-config.yaml
  envoy -c /tmp/ccr-proxy-config.yaml

else 
  export CCR_SIDECAR_PORT=${CCR_SIDECAR_PORT:-8281} 
  cat ccr-proxy-config-debug.yaml | envsubst '$CCR_SIDECAR_PORT' > /tmp/ccr-proxy-config-debug.yaml
  envoy -l debug -c /tmp/ccr-proxy-config-debug.yaml
fi

