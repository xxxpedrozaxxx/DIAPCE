"""Flask application factory."""
import os

from dotenv import load_dotenv
from flask import Flask, jsonify

from .config import Config
from .extensions import api, db, jwt


def create_app(config_object=Config) -> Flask:
    load_dotenv()
    app = Flask(__name__)
    app.config.from_object(config_object)
    if os.getenv("DATABASE_URL"):
        app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv("DATABASE_URL")
    if os.getenv("JWT_SECRET_KEY"):
        app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY")

    db.init_app(app)
    jwt.init_app(app)
    api.init_app(app)

    from . import models  # noqa: F401  (registra las tablas)
    from .resources import BLUEPRINTS

    for blp in BLUEPRINTS:
        api.register_blueprint(blp)

    @app.get("/api/health")
    def health():
        return jsonify({"status": "ok", "service": "diapce-api"})

    @jwt.unauthorized_loader
    def _unauthorized(reason):
        return jsonify({"code": 401, "status": "Unauthorized", "message": reason}), 401

    @jwt.invalid_token_loader
    def _invalid(reason):
        return jsonify({"code": 401, "status": "Unauthorized", "message": reason}), 401

    # Un token válido de un usuario que ya no existe (p. ej. base recreada)
    # se rechaza con 401 en vez de fallar después por la llave foránea.
    @jwt.user_lookup_loader
    def _lookup_user(_header, payload):
        return db.session.get(models.User, int(payload["sub"]))

    @jwt.user_lookup_error_loader
    def _user_not_found(_header, _payload):
        return jsonify({"code": 401, "status": "Unauthorized", "message": "Sesión expirada, inicia sesión de nuevo"}), 401

    return app
