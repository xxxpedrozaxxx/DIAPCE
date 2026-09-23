"""Esquemas marshmallow (validación de entrada y serialización de salida).

Los nombres de campo coinciden con `toMap()` / `fromMap()` de los modelos
Dart (lib/models/*.dart) para que el cliente no cambie su formato.
"""
from marshmallow import Schema, fields, validate


# ── Auth ────────────────────────────────────────────────────────────────
class RegisterSchema(Schema):
    email = fields.Email(required=True)
    password = fields.Str(required=True, validate=validate.Length(min=6), load_only=True)


class LoginSchema(RegisterSchema):
    pass


class UserSchema(Schema):
    id = fields.Int(dump_only=True)
    email = fields.Email(dump_only=True)


class TokenSchema(Schema):
    access_token = fields.Str()
    user = fields.Nested(UserSchema)


# ── Catálogos ───────────────────────────────────────────────────────────
class TipoEstructuraSchema(Schema):
    id = fields.Int(dump_only=True)
    codigo = fields.Str()
    nombre = fields.Str()


class MaterialSchema(Schema):
    id = fields.Int(dump_only=True)
    name = fields.Str(required=True)
    unit = fields.Str(required=True)
    density = fields.Float(allow_none=True)
    cost_per_unit = fields.Float(allow_none=True)
    description = fields.Str(allow_none=True)
    created_at = fields.DateTime(dump_only=True)


class AditivoSchema(Schema):
    id = fields.Int()
    codigo = fields.Str()
    porcentaje_aplicado = fields.Str()
    tipo_aditivo = fields.Str(attribute="tipo_aditivo.nombre")
    producto = fields.Str(attribute="producto.nombre_producto")
    marca = fields.Str(attribute="producto.marca")


# ── Mezclas ─────────────────────────────────────────────────────────────
class MaterialInMixtureSchema(Schema):
    """Mismo formato que `MaterialInMixture.fromMap` en Dart (JOIN aplanado)."""

    id = fields.Int(attribute="material_id")
    name = fields.Str(attribute="material.name")
    unit = fields.Str(attribute="material.unit")
    density = fields.Float(attribute="material.density", allow_none=True)
    cost_per_unit = fields.Float(attribute="material.cost_per_unit", allow_none=True)
    description = fields.Str(attribute="material.description", allow_none=True)
    quantity = fields.Float()
    percentage = fields.Float(allow_none=True)


class MixtureSchema(Schema):
    id = fields.Int(dump_only=True, allow_none=True)
    name = fields.Str(required=True)
    description = fields.Str(allow_none=True)
    total_volume = fields.Float(allow_none=True)
    project_id = fields.Int(allow_none=True)
    created_at = fields.DateTime(dump_only=True, allow_none=True)
    materials = fields.List(fields.Nested(MaterialInMixtureSchema), dump_only=True)


class MixturePreviewQuerySchema(Schema):
    work_type = fields.Str(required=True)
    relacion_ac = fields.Float(required=True, validate=validate.Range(min=0.2, max=1.0))
    aditivo_id = fields.Int(load_default=None, allow_none=True)
    resistance_target = fields.Float(load_default=None, allow_none=True)  # compatibilidad


class MixtureMaterialInputSchema(Schema):
    material_id = fields.Int(required=True)
    quantity = fields.Float(required=True, validate=validate.Range(min=0))


class MixtureStatsSchema(Schema):
    totalQuantity = fields.Float()
    totalCost = fields.Float()
    materialCount = fields.Float()
    averageCostPerKg = fields.Float()


# ── Proyectos ───────────────────────────────────────────────────────────
class ProjectSchema(Schema):
    id = fields.Int(dump_only=True)
    user_id = fields.Int(dump_only=True)
    project_name = fields.Str(required=True, validate=validate.Length(min=1, max=128))
    selected_date = fields.Str(allow_none=True)
    selected_image_path = fields.Str(allow_none=True)
    creator_name = fields.Str(allow_none=True)
    # Código de tipos_estructura (Puentes | Tuneles | Muros). El cliente lo
    # sigue llamando work_type.
    work_type = fields.Str(required=True)
    resistance_target = fields.Float(required=True, validate=validate.Range(min=24, max=57))
    temperature = fields.Int(required=True)
    humidity = fields.Int(required=True)
    relacion_ac = fields.Float(required=True)
    aditivo_id = fields.Int(allow_none=True)
    resistencia_predicha_7d = fields.Float(allow_none=True)
    resistencia_predicha_14d = fields.Float(allow_none=True)
    resistencia_predicha_28d = fields.Float(allow_none=True)
    mixture_id = fields.Int(allow_none=True)
    created_at = fields.DateTime(dump_only=True)


class ProjectPartialSchema(ProjectSchema):
    """PUT parcial: ningún campo obligatorio."""

    def __init__(self, *args, **kwargs):
        kwargs.setdefault("partial", True)
        super().__init__(*args, **kwargs)


# ── Experimentos / análisis ─────────────────────────────────────────────
class ConditionsQuerySchema(Schema):
    temperatura = fields.Int(required=True)
    humedad = fields.Int(required=True)
    relacion_ac = fields.Float(required=True)
    aditivo_id = fields.Int(load_default=1)


class HumidityQuerySchema(Schema):
    temperatura = fields.Int(required=True)


class RelacionAcQuerySchema(Schema):
    temperatura = fields.Int(required=True)
    humedad = fields.Int(required=True)


class AditivoQuerySchema(Schema):
    temperatura = fields.Int(required=True)
    humedad = fields.Int(required=True)
    relacion_ac = fields.Float(required=True)


class AgeStatSchema(Schema):
    edad_dias = fields.Int()
    promedio = fields.Float()
    desviacion = fields.Float(allow_none=True)
    minimo = fields.Float()
    maximo = fields.Float()
    num_muestras = fields.Int()


class CurveSchema(Schema):
    a = fields.Float()
    b = fields.Float()
    r2 = fields.Float(allow_none=True)
    formula = fields.Str()


class PredictionSchema(Schema):
    dias_7 = fields.Float(allow_none=True)
    dias_14 = fields.Float(allow_none=True)
    dias_28 = fields.Float(allow_none=True)
    por_edad = fields.List(fields.Nested(AgeStatSchema))
    curva = fields.Nested(CurveSchema, allow_none=True)
    curva_estimada = fields.Dict(keys=fields.Int(), values=fields.Float())
    num_muestras = fields.Int()


TIPOS_ESTRUCTURA = ["Puentes", "Tuneles", "Muros"]


def estructura_filter():
    """Filtro de análisis: un tipo de estructura o los ensayos históricos sin clasificar."""
    return fields.Str(
        load_default=None, allow_none=True,
        validate=validate.OneOf(TIPOS_ESTRUCTURA + ["sin_clasificar"]),
    )


class OptimalRangesQuerySchema(Schema):
    resistencia_objetivo = fields.Float(required=True, validate=validate.Range(min=24, max=57))
    tipo_estructura = estructura_filter()


class RangeSchema(Schema):
    min = fields.Float()
    max = fields.Float()
    valores = fields.List(fields.Float())


class AditivoRangeSchema(RangeSchema):
    """Cantidad de aditivo (%) que alcanza el objetivo, para un tipo de aditivo."""

    tipo_aditivo = fields.Str()
    combinaciones = fields.Int()


class CombinationSchema(Schema):
    temperatura = fields.Int()
    humedad = fields.Int()
    relacion_ac = fields.Float()
    aditivo_id = fields.Int()
    aditivo_codigo = fields.Str()
    tipo_aditivo = fields.Str()
    porcentaje_aditivo = fields.Float()
    promedio_28d = fields.Float()
    num_muestras = fields.Int()


class OptimalRangesSchema(Schema):
    resistencia_objetivo = fields.Float()
    tipo_estructura = fields.Str(allow_none=True)
    total_combinaciones = fields.Int()
    combinaciones_que_cumplen = fields.Int()
    rangos = fields.Dict(keys=fields.Str(), values=fields.Nested(RangeSchema))
    aditivos = fields.List(fields.Nested(AditivoRangeSchema))
    mejores = fields.List(fields.Nested(CombinationSchema))


class DispersionQuerySchema(Schema):
    variable = fields.Str(
        required=True,
        validate=validate.OneOf(["temperatura", "humedad", "relacion_ac", "porcentaje_aditivo"]),
    )
    edad_dias = fields.Int(load_default=28, validate=validate.OneOf([7, 14, 28]))
    tipo_aditivo = fields.Str(load_default=None, allow_none=True)
    tipo_estructura = estructura_filter()


class DispersionPointSchema(Schema):
    x = fields.Float()
    y = fields.Float()
    tipo_aditivo = fields.Str()
    aditivo_codigo = fields.Str()


class DispersionRowSchema(Schema):
    valor = fields.Float()
    num_muestras = fields.Int()
    promedio = fields.Float()
    desviacion = fields.Float(allow_none=True)
    coef_variacion = fields.Float(allow_none=True)
    minimo = fields.Float()
    maximo = fields.Float()
    rango = fields.Float()


class DispersionSchema(Schema):
    variable = fields.Str()
    edad_dias = fields.Int()
    tipo_aditivo = fields.Str(allow_none=True)
    tipo_estructura = fields.Str(allow_none=True)
    num_puntos = fields.Int()
    correlacion = fields.Float(allow_none=True)
    tipos_aditivo = fields.List(fields.Str())
    puntos = fields.List(fields.Nested(DispersionPointSchema))
    tabla = fields.List(fields.Nested(DispersionRowSchema))


class CalibrationRowSchema(Schema):
    temperatura = fields.Int()
    humedad = fields.Int()
    relacion_ac = fields.Float()
    aditivo_id = fields.Int()
    a = fields.Float()
    b = fields.Float()
    r2 = fields.Float(allow_none=True)
    mae = fields.Float()
    rmse = fields.Float()
    num_muestras = fields.Int()


class ErrorMetricsSchema(Schema):
    n = fields.Int()
    mae = fields.Float(allow_none=True)
    rmse = fields.Float(allow_none=True)
    mape = fields.Float(allow_none=True)


class AgeErrorMetricsSchema(ErrorMetricsSchema):
    edad_dias = fields.Int()


class ModelValidationSchema(ErrorMetricsSchema):
    por_edad = fields.List(fields.Nested(AgeErrorMetricsSchema))


class ValidationSchema(Schema):
    metodo = fields.Str()
    curva_log = fields.Nested(ModelValidationSchema)
    promedio_edad = fields.Nested(ModelValidationSchema)


class CalibrationSchema(Schema):
    modelo = fields.Str()
    num_ensayos = fields.Int()
    combinaciones = fields.Int()
    mae_global = fields.Float()
    rmse_global = fields.Float()
    r2_promedio = fields.Float(allow_none=True)
    validacion = fields.Nested(ValidationSchema)
    detalle = fields.List(fields.Nested(CalibrationRowSchema))


class CalibrationRunSchema(Schema):
    """Una ejecución guardada en el historial de calibración."""

    id = fields.Int()
    created_at = fields.DateTime()
    motivo = fields.Str()
    num_ensayos = fields.Int()
    num_combinaciones = fields.Int()
    mae_ajuste = fields.Float()
    rmse_ajuste = fields.Float()
    r2_promedio = fields.Float(allow_none=True)
    mae_validacion = fields.Float(allow_none=True)
    rmse_validacion = fields.Float(allow_none=True)
    mape_validacion = fields.Float(allow_none=True)


# ── Estadística inferencial y optimización ─────────────────────────────
class AnovaQuerySchema(Schema):
    edad_dias = fields.Int(load_default=28, validate=validate.OneOf([7, 14, 28]))


class AnovaRowSchema(Schema):
    fuente = fields.Str()
    sc = fields.Float()
    gl = fields.Int()
    cm = fields.Float(allow_none=True)
    f = fields.Float(allow_none=True)
    p = fields.Float(allow_none=True)
    eta2_parcial = fields.Float()


class LevelMeanSchema(Schema):
    nivel = fields.Raw()
    n = fields.Int()
    media = fields.Float()


class AnovaSchema(Schema):
    edad_dias = fields.Int()
    n = fields.Int()
    metodo = fields.Str()
    r2 = fields.Float()
    filas = fields.List(fields.Nested(AnovaRowSchema))
    residual = fields.Dict()
    total = fields.Dict()
    medias = fields.Dict(keys=fields.Str(), values=fields.List(fields.Nested(LevelMeanSchema)))


class CoefficientSchema(Schema):
    termino = fields.Str()
    valor = fields.Float()
    error_estandar = fields.Float()
    t = fields.Float()
    p = fields.Float()


class RegressionSchema(Schema):
    ecuacion = fields.Str()
    n = fields.Int()
    r2 = fields.Float()
    r2_ajustado = fields.Float()
    rmse = fields.Float()
    coeficientes = fields.List(fields.Nested(CoefficientSchema))
    rangos_validos = fields.Dict()
    validacion = fields.Nested(ModelValidationSchema)


class OptimizeInputSchema(Schema):
    resistencia_objetivo = fields.Float(required=True, validate=validate.Range(min=17, max=60))
    temperatura = fields.Float(required=True, validate=validate.Range(min=0, max=45))
    humedad = fields.Float(required=True, validate=validate.Range(min=0, max=100))
    tipo_estructura = fields.Str(required=True, validate=validate.OneOf(TIPOS_ESTRUCTURA))
    edad_dias = fields.Int(load_default=28, validate=validate.OneOf([7, 14, 28]))


class MixMaterialSchema(Schema):
    nombre = fields.Str()
    unidad = fields.Str()
    cantidad = fields.Float()


class OptimizeAlternativeSchema(Schema):
    aditivo_id = fields.Int()
    aditivo_codigo = fields.Str()
    tipo_aditivo = fields.Str()
    dosis_pct = fields.Float()
    relacion_ac = fields.Float()
    prediccion = fields.Float()
    margen = fields.Float()
    factible = fields.Bool()
    cemento = fields.Float()
    costo_referencia = fields.Float(allow_none=True)
    materiales = fields.List(fields.Nested(MixMaterialSchema))
    descripcion = fields.Str()


class OptimizeSchema(Schema):
    resistencia_especificada = fields.Float()
    resistencia_requerida = fields.Float()
    desviacion_estandar = fields.Float()
    condiciones = fields.Dict()
    criterio = fields.Str()
    modelo = fields.Dict()
    advertencias = fields.List(fields.Str())
    alternativas = fields.List(fields.Nested(OptimizeAlternativeSchema))


# ── Registro de ensayos ─────────────────────────────────────────────────
ORIGENES = ["semilla", "registro", "importacion"]


class ResultadoInputSchema(Schema):
    """Ensayo de compresión de un cilindro registrado desde la aplicación."""

    temperatura = fields.Int(required=True, validate=validate.Range(min=-10, max=60))
    humedad = fields.Int(required=True, validate=validate.Range(min=0, max=100))
    relacion_ac = fields.Float(required=True, validate=validate.Range(min=0.2, max=1.0))
    edad_dias = fields.Int(required=True, validate=validate.Range(min=1, max=365))
    resistencia_mpa = fields.Float(
        required=True, validate=validate.Range(min=0, max=150, min_inclusive=False)
    )
    aditivo_id = fields.Int(required=True)
    tipo_estructura = fields.Str(required=True, validate=validate.OneOf(TIPOS_ESTRUCTURA))
    fecha_ensayo = fields.Date(load_default=None, allow_none=True)
    observaciones = fields.Str(
        load_default=None, allow_none=True, validate=validate.Length(max=500)
    )


class ResultadoSchema(Schema):
    id = fields.Int()
    temperatura = fields.Int()
    humedad = fields.Int()
    relacion_ac = fields.Float()
    edad_dias = fields.Int()
    resistencia_mpa = fields.Float()
    aditivo_id = fields.Int()
    aditivo_codigo = fields.Str(attribute="aditivo.codigo")
    tipo_estructura = fields.Str(attribute="tipo_estructura.codigo", allow_none=True)
    origen = fields.Str()
    fecha_ensayo = fields.Date(allow_none=True)
    observaciones = fields.Str(allow_none=True)
    registrado_por = fields.Int(allow_none=True)
    created_at = fields.DateTime()


class ResultadoPageSchema(Schema):
    total = fields.Int()
    page = fields.Int()
    per_page = fields.Int()
    items = fields.List(fields.Nested(ResultadoSchema))


class ResultadoQuerySchema(Schema):
    tipo_estructura = estructura_filter()
    origen = fields.Str(load_default=None, allow_none=True, validate=validate.OneOf(ORIGENES))
    edad_dias = fields.Int(load_default=None, allow_none=True)
    page = fields.Int(load_default=1, validate=validate.Range(min=1))
    per_page = fields.Int(load_default=50, validate=validate.Range(min=1, max=200))


class ImportCsvSchema(Schema):
    csv = fields.Str(required=True, validate=validate.Length(min=1))


class ImportErrorSchema(Schema):
    linea = fields.Int()
    mensaje = fields.Str()


class ImportResultSchema(Schema):
    insertados = fields.Int()
    errores = fields.List(fields.Nested(ImportErrorSchema))
