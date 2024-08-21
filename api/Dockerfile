FROM python:3.12

RUN apt-get update \
    && apt-get -y install libpq-dev gcc

COPY . .

RUN pip install -r requirements.txt

CMD ["fastapi", "run", "main.py", "--port", "8000"]