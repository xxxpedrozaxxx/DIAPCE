"""Datos experimentales y modelos matemáticos: /api/experiments/*

- options/*      → selectores en cascada (lo que hoy consulta create_proyect_screen.dart)
- predict        → estadística por edad + curva f(t) = a + b·ln(t)
- optimal-ranges → rangos de variables que alcanzan una resistencia objetivo
- dispersion     → ensayos individuales vs. una variable + tabla de dispersión
- calibration    → también /calibration/run (guardar) y /calibration/history
- anova          → análisis de varianza tipo II
- model          → regresión múltiple y su validación por combinación
- optimize       → dosificación de menor cemento que alcanza f'cr (ACI 318 / 211.1)
- calibration    → error del modelo contra los ensayos reales
"""
from flask.views import MethodView
from flask_jwt_extended import get_jwt_identity, jwt_required
from flask_smorest import Blueprint
from sqlalchemy import select

from ..analysis import (
    calibration,
    dispersion,
    optimal_ranges,
    predict_strength,
    save_calibration,
)
from ..estadistica import anova, optimizar, regresion
from ..extensions import db
from ..models import Aditivo, Calibracion, ResultadoConcreto
from ..schemas import (
    AditivoQuerySchema,
    AditivoSchema,
    AnovaQuerySchema,
    AnovaSchema,
    OptimizeInputSchema,
    OptimizeSchema,
    RegressionSchema,
    CalibrationRunSchema,
    CalibrationSchema,
    ConditionsQuerySchema,
    DispersionQuerySchema,
    DispersionSchema,
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
        return optimal_ranges(q["resistencia_objetivo"], q.get("tipo_estructura"))


@blp.route("/dispersion")
class Dispersion(MethodView):
    @jwt_required()
    @blp.arguments(DispersionQuerySchema, location="query")
    @blp.response(200, DispersionSchema)
    def get(self, q):
        """Ensayos individuales de resistencia vs. una variable y tabla de dispersión."""
        return dispersion(
            q["variable"], q["edad_dias"], q.get("tipo_aditivo"), q.get("tipo_estructura")
        )


@blp.route("/calibration")
class Calibration(MethodView):
    @jwt_required()
    @blp.response(200, CalibrationSchema)
    def get(self):
        """Error de ajuste (MAE / RMSE / R²) y de validación cruzada del modelo."""
        return calibration()


@blp.route("/anova")
class Anova(MethodView):
    @jwt_required()
    @blp.arguments(AnovaQuerySchema, location="query")
    @blp.response(200, AnovaSchema)
    def get(self, q):
        """ANOVA (tipo II) de la resistencia: temperatura, humedad, a/c, aditivo e interacciones."""
        return anova(q["edad_dias"])


@blp.route("/model")
class Model(MethodView):
    @jwt_required()
    @blp.response(200, RegressionSchema)
    def get(self):
        """Modelo de regresión múltiple: coeficientes, ajuste y validación por combinación."""
        resultado = regresion()
        resultado.pop("_beta")
        return resultado


@blp.route("/optimize")
class Optimize(MethodView):
    @jwt_required()
    @blp.arguments(OptimizeInputSchema)
    @blp.response(200, OptimizeSchema)
    def post(self, data):
        """Dosificación de menor contenido de cemento que alcanza f'cr en el clima de la obra."""
        return optimizar(
            data["resistencia_objetivo"], data["temperatura"], data["humedad"],
            data["tipo_estructura"], data["edad_dias"],
        )


@blp.route("/calibration/run")
class CalibrationRun(MethodView):
    @jwt_required()
    @blp.response(201, CalibrationRunSchema)
    def post(self):
        """Recalibra el modelo con todos los ensayos y guarda la ejecución en el historial."""
        return save_calibration("manual", int(get_jwt_identity()))


@blp.route("/calibration/history")
class CalibrationHistory(MethodView):
    @jwt_required()
    @blp.response(200, CalibrationRunSchema(many=True))
    def get(self):
        """Historial de calibraciones, de la más antigua a la más reciente (últimas 50)."""
        rows = db.session.scalars(
            select(Calibracion).order_by(Calibracion.id.desc()).limit(50)
        ).all()
        return list(reversed(rows))
