FROM python:3.11

WORKDIR /app

RUN pip install kubernetes

COPY auto_heal_pods.py .

CMD ["python", "auto_heal_pods.py"]