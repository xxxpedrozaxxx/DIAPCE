"""Datos experimentales y modelos matemáticos: /api/experiments/*

- options/*      → selectores en cascada (lo que hoy consulta create_proyect_screen.dart)
- predict        → estadística por edad + curva f(t) = a + b·ln(t)
- optimal-ranges → rangos de variables que alcanzan una resistencia objetivo
- calibration    → error del modelo contra los ensayos reales
"""
from flask.views import MethodView
from flask_jwt_extended import jwt_required
from flask_smorest import Blueprint
from sqlalchemy import select

from ..analysis import calibration, optimal_ranges, predict_strength
from ..extensions import db
from ..models import Aditivo, ResultadoConcreto
from ..schemas import (
    AditivoQuerySchema,
    AditivoSchema,
    CalibrationSchema,
    ConditionsQuerySchema,
    HumidityQuerySchema,
    OptimalRangesQuerySchema,
    OptimalRangesSchema,
    PredictionSchema,
    RelacionAcQuerySchema,
)

blp = Blueprint(
    "experiments", __name__, url_prefix="/api/experiments",
    description="Datos experimentales y modelos matemáticos",
)


@blp.route("/options/temperatures")
class TemperatureOptions(MethodView):
    @jwt_required()
    @blp.response(200)
    def get(self):
        """Temperaturas con ensayos registrados (ya no están hardcodeadas)."""
        return db.session.scalars(
            select(ResultadoConcreto.temperatura).distinct().order_by(ResultadoConcreto.temperatura)
        ).all()


@blp.route("/options/humidity")
class HumidityOptions(MethodView):
    @jwt_required()
    @blp.arguments(HumidityQuerySchema, location="query")
    @blp.response(200)
    def get(self, q):
        return db.session.scalars(
            select(ResultadoConcreto.humedad)
            .where(ResultadoConcreto.temperatura == q["temperatura"])
            .distinct().order_by(ResultadoConcreto.humedad)
        ).all()


@blp.route("/options/relacion-ac")
class RelacionAcOptions(MethodView):
    @jwt_required()
    @blp.arguments(RelacionAcQuerySchema, location="query")
    @blp.response(200)
    def get(self, q):
        return db.session.scalars(
            select(ResultadoConcreto.relacion_ac)
            .where(
                ResultadoConcreto.temperatura == q["temperatura"],
                ResultadoConcreto.humedad == q["humedad"],
            )
            .distinct().order_by(ResultadoConcreto.relacion_ac)
        ).all()


@blp.route("/options/aditivos")
class AditivoOptions(MethodView):
    @jwt_required()
    @blp.arguments(AditivoQuerySchema, location="query")
    @blp.response(200, AditivoSchema(many=True))
    def get(self, q):
        """Aditivos con ensayos para la combinación (equivale a getAditivosConCodigos)."""
        ids = select(ResultadoConcreto.aditivo_id).where(
            ResultadoConcreto.temperatura == q["temperatura"],
            ResultadoConcreto.humedad == q["humedad"],
            ResultadoConcreto.relacion_ac == q["relacion_ac"],
        ).distinct()
        return db.session.scalars(
            select(Aditivo).where(Aditivo.id.in_(ids)).order_by(Aditivo.id)
        ).all()


@blp.route("/predict")
class Predict(MethodView):
    @jwt_required()
    @blp.arguments(ConditionsQuerySchema, location="query")
    @blp.response(200, PredictionSchema)
    def get(self, q):
        """Resistencia estimada a 7/14/28 días y curva de desarrollo."""
        return predict_strength(q["temperatura"], q["humedad"], q["relacion_ac"], q["aditivo_id"])


@blp.route("/optimal-ranges")
class OptimalRanges(MethodView):
    @jwt_required()
    @blp.arguments(OptimalRangesQuerySchema, location="query")
    @blp.response(200, OptimalRangesSchema)
    def get(self, q):
        """Rangos de temperatura/humedad/a/c/aditivo que alcanzan el objetivo a 28 d."""
        return optimal_ranges(q["resistencia_objetivo"])


@blp.route("/calibration")
class Calibration(MethodView):
    @jwt_required()
    @blp.response(200, CalibrationSchema)
    def get(self):
        """MAE / RMSE / R² del modelo por combinación y global."""
        return calibration()
