# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

import binascii
import sys

if len(sys.argv) != 2:
    print("Usage: python hexstring.py <filename>")
    sys.exit(-1)

bFile = open(sys.argv[1],'rb') 
bData = bFile.read(32)
print(binascii.hexlify(bData))
