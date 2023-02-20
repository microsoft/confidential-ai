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

