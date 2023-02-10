
#!/bin/bash

# Generate signing keys
openssl ecparam -genkey -name secp384r1 -noout -out keys/signing_private.pem
openssl ec -in keys/signing_private.pem -pubout -out keys/signing_public.pem

# Sign models
python3 sign.py keys/signing_private.pem model_repository

# Generate encrypted file system image
./generatefs.sh -d model_repository -k keys/modelkey.bin -i model.img
