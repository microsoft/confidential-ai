FROM kapilvaswani/confidential-envoy:latest

RUN sudo apt-get install -y gettext

WORKDIR "/home/envoy"

COPY proxy-config.yaml proxy-config.yaml
COPY --chmod=755 bootstrap.sh bootstrap.sh

USER "envoy"