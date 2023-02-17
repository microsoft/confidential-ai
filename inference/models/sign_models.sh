#!/bin/bash

# Generate signing keys
openssl ecparam -genkey -name secp384r1 -noout -out signing_private.pem
openssl ec -in signing_private.pem -pubout -out signing_public.pem

# Sign models
python3 sign.py signing_private.pem model_repository
