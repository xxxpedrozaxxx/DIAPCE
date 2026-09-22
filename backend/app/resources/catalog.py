"""Catálogos de solo lectura: /api/catalog/*"""
from flask.views import MethodView
from flask_jwt_extended import jwt_required
from flask_smorest import Blueprint
from sqlalchemy import select

from ..extensions import db
from ..models import Aditivo, Material, TipoEstructura
from ..schemas import AditivoSchema, MaterialSchema, TipoEstructuraSchema

blp = Blueprint("catalog", __name__, url_prefix="/api/catalog", description="Catálogos")


@blp.route("/materials")
class Materials(MethodView):
    @jwt_required()
    @blp.response(200, MaterialSchema(many=True))
    def get(self):
        return db.session.scalars(select(Material).order_by(Material.id)).all()


@blp.route("/aditivos")
class Aditivos(MethodView):
    @jwt_required()
    @blp.response(200, AditivoSchema(many=True))
    def get(self):
        return db.session.scalars(select(Aditivo).order_by(Aditivo.id)).all()


@blp.route("/tipos-estructura")
class TiposEstructura(MethodView):
    @jwt_required()
    @blp.response(200, TipoEstructuraSchema(many=True))
    def get(self):
        return db.session.scalars(select(TipoEstructura).order_by(TipoEstructura.id)).all()
