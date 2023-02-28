#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Generate encrypted file system image
./generatefs.sh -d model_repository -k modelkey.bin -i model.img
