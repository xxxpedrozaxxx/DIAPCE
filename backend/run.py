"""Arranque en desarrollo: python run.py  (Swagger en http://localhost:5000/api/docs)"""
import os

from app import create_app

app = create_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("API_PORT", "5000")), debug=os.getenv("FLASK_DEBUG") == "1")
