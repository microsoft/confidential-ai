FROM mcr.microsoft.com/aci/ml-inference-demo-proxy:v1

RUN sudo apt-get install -y gettext

WORKDIR "/home/envoy"

COPY proxy-config-template.yaml proxy-config-template.yaml
COPY --chmod=755 bootstrap.sh bootstrap.sh

USER "envoy"