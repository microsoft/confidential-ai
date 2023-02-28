# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# ONNX densenet
mkdir -p model_repository/densenet_onnx
wget -O model_repository/densenet_onnx/config.pbtxt \
     https://raw.githubusercontent.com/triton-inference-server/server/main/docs/examples/model_repository/densenet_onnx/config.pbtxt

wget -O model_repository/densenet_onnx/densenet_labels.txt \
     https://raw.githubusercontent.com/triton-inference-server/server/main/docs/examples/model_repository/densenet_onnx/densenet_labels.txt
     
mkdir -p model_repository/densenet_onnx/1
wget -O model_repository/densenet_onnx/1/model.onnx \
     https://contentmamluswest001.blob.core.windows.net/content/14b2744cf8d6418c87ffddc3f3127242/9502630827244d60a1214f250e3bbca7/08aed7327d694b8dbaee2c97b8d0fcba/densenet121-1.2.onnx
