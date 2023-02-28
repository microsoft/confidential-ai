FROM nvcr.io/nvidia/tritonserver:22.05-py3
RUN apt-get update && apt -y install python3-openssl
COPY verify.py /opt/verify/verify.py
COPY --chmod=755 verify_and_run.sh /opt/verify/verify_and_run.sh
