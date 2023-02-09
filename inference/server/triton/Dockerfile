FROM nvcr.io/nvidia/tritonserver:22.08-pyt-python-py3
RUN apt-get update && apt -y install python3-openssl
COPY verify.py verify.py
COPY verify_and_run.sh verify_and_run.sh
