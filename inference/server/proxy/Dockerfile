FROM mcr.microsoft.com/aci/ml-inference-demo-proxy:v1

RUN sudo apt-get update && sudo apt-get install -y gettext

WORKDIR "/home/envoy"

COPY proxy-config.yaml proxy-config.yaml
COPY --chmod=755 bootstrap.sh bootstrap.sh
COPY --chmod=755 wait-for-it.sh wait-for-it.sh

USER "envoy"