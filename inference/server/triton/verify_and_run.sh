#!/bin/bash

# first attribute base64-encoded public key pem 
# second attribute path to models directory

echo $1 | base64 --decode > /opt/verify/pubkey.pem

while [ ! -d "$2" ]
do
   echo "Waiting on $2 to appear."
   sleep 1
done

result=`python3 /opt/verify/verify.py /opt/verify/pubkey.pem $2`

rm /opt/verify/pubkey.pem

if [[ $result == "Verified" ]]; then
   echo "Models verified. Starting triton inference server"
   /opt/tritonserver/bin/tritonserver --model-repository=$2
else
   echo "Models not verified. Exiting now"
fi
