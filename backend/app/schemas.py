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
    resistance_target = fields.Float(required=True)


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


class OptimalRangesQuerySchema(Schema):
    resistencia_objetivo = fields.Float(required=True, validate=validate.Range(min=24, max=57))


class RangeSchema(Schema):
    min = fields.Float()
    max = fields.Float()
    valores = fields.List(fields.Float())


class CombinationSchema(Schema):
    temperatura = fields.Int()
    humedad = fields.Int()
    relacion_ac = fields.Float()
    aditivo_id = fields.Int()
    aditivo_codigo = fields.Str()
    promedio_28d = fields.Float()
    num_muestras = fields.Int()


class OptimalRangesSchema(Schema):
    resistencia_objetivo = fields.Float()
    total_combinaciones = fields.Int()
    combinaciones_que_cumplen = fields.Int()
    rangos = fields.Dict(keys=fields.Str(), values=fields.Nested(RangeSchema))
    mejores = fields.List(fields.Nested(CombinationSchema))


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


class CalibrationSchema(Schema):
    modelo = fields.Str()
    combinaciones = fields.Int()
    mae_global = fields.Float()
    rmse_global = fields.Float()
    r2_promedio = fields.Float(allow_none=True)
    detalle = fields.List(fields.Nested(CalibrationRowSchema))
