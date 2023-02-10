import os
import OpenSSL
from OpenSSL import crypto
from pathlib import Path
import sys

if len(sys.argv) != 3:
    print("Usage: python sign.py <path to the private signing key PEM file> <path to the file>")
    sys.exit(-1)

def sign(private_key_path, data_file_path):

    key_file = open(private_key_path, "r")
    key = key_file.read()
    key_file.close()

    if key.startswith('-----BEGIN '):
        pkey = crypto.load_privatekey(crypto.FILETYPE_PEM, key)
    else:
        print("Expected private key formatted in PEM")
        return False

    the_file = open(data_file_path, "rb")
    sign = OpenSSL.crypto.sign(pkey, the_file.read(), "sha1") 
    the_file.close()

    the_sig_file = open(Path(data_file_path).parent.joinpath('signature.bin'), "wb")
    the_sig_file.write(sign)
    the_sig_file.close()

    return True

if __name__ == "__main__":

    if len(sys.argv) != 3:
        print("Usage: python sign.py <path to the private signing key PEM file> <path to the directory containing files>")
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
        if sign(sys.argv[1], name) is True:
             print("Signed ", name)