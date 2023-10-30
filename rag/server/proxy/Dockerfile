FROM kapilvaswani/confidential-envoy:latest

ENV DEBIAN_FRONTEND=noninteractive 

RUN apt-get update && apt-get install -y \
    gettext \
    build-essential \
    libcurl4-openssl-dev \
    libjsoncpp-dev \
    libboost-all-dev \
    cmake \
    nlohmann-json3-dev \
    wget \
    tpm2-tools 

RUN apt-get install -y git

WORKDIR "/home/envoy"

RUN wget https://packages.microsoft.com/repos/azurecore/pool/main/a/azguestattestation1/azguestattestation1_1.0.5_amd64.deb
RUN dpkg -i azguestattestation1_1.0.5_amd64.deb

USER "envoy"

RUN git clone https://github.com/Azure/confidential-computing-cvm-guest-attestation.git
WORKDIR ./confidential-computing-cvm-guest-attestation/cvm-attestation-sample-app
RUN cmake . 
RUN make

WORKDIR "/home/envoy"

COPY proxy-config.yaml proxy-config.yaml
COPY --chmod=755 bootstrap.sh bootstrap.sh