# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

import glob
import os
import OpenSSL
from OpenSSL import crypto
from pathlib import Path
import sys

def verify(public_key_path, data_path, signature_path):
    public_key_file = open(public_key_path, "r")
    public_key = public_key_file.read()
    public_key_file.close()

    if public_key.startswith('-----BEGIN '):
        key = crypto.load_publickey(crypto.FILETYPE_PEM, public_key)
        x509 = OpenSSL.crypto.X509()
        x509.set_pubkey(key)
    else:
        print("Expected public key formatted in PEM")
        sys.exit(-1)

    the_data_file = open(data_path, "rb")
    the_data = the_data_file.read()
    the_data_file.close()

    the_sig_file = open(signature_path, "rb")
    the_sig = the_sig_file.read()
    the_sig_file.close()

    try:
        OpenSSL.crypto.verify(x509, the_sig, the_data, "sha1")            
        return True
    except:
        return False

if __name__ == "__main__":

    if len(sys.argv) != 3:
        print("Usage: python verify.py <path to the public signing key PEM file> <path to the directory containing files>")
        sys.exit(-1)
    
    #we shall store all the file names in this list
    filelist = []

    for root, dirs, files in os.walk(sys.argv[2]):
        for file in files:
            if(file.startswith("model")):
                #append the file name to the list
                filelist.append(os.path.join(root,file))

    #print all the file names
    for name in filelist:        
        if verify(sys.argv[1], name, str(Path(name).parent.joinpath("signature.bin"))) is False:
             sys.exit(-1)

    print("Verified")

        
