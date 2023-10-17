FROM langchain/langchain

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --upgrade -r requirements.txt

RUN pip install flask

COPY bot.py .
COPY utils.py .
COPY chains.py .
COPY templates ./templates

EXPOSE 8501

ENTRYPOINT ["python3", "bot.py"]
