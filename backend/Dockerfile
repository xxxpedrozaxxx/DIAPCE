FROM python:3.12-slim
WORKDIR /app
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/ .
# El seed necesita el CSV del cliente
COPY lib/data/csv_datos_1.1.csv /lib/data/csv_datos_1.1.csv
ENV API_PORT=5000
EXPOSE 5000
CMD ["sh", "-c", "python seed.py && gunicorn -b 0.0.0.0:5000 -w 2 run:app"]
