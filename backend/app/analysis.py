"""Módulo de modelos matemáticos de análisis de mezclas (objetivos 2 y 3).

Se ejecuta en el servidor sobre la tabla `resultados_concreto`:

1. `predict_strength`  — estadística por edad (promedio, desviación, min, max)
   para la combinación exacta de condiciones, más el ajuste de la curva de
   desarrollo de resistencia  f(t) = a + b·ln(t)  por mínimos cuadrados, que
   permite estimar la resistencia a cualquier edad (no solo 7/14/28 días).
2. `optimal_ranges`    — dado un objetivo de resistencia a 28 días, encuentra
   las combinaciones (temperatura, humedad, a/c, aditivo) cuyo promedio lo
   alcanza y devuelve el rango (min/max/valores) de cada variable, con la
   cantidad de aditivo separada por tipo de aditivo.
3. `dispersion`        — ensayos individuales de resistencia vs. una variable
   (temperatura, humedad, a/c o cantidad de aditivo) y tabla de dispersión
   por valor: n, promedio, desviación, coeficiente de variación, min, max.
4. `calibration`      — mide el error del modelo (MAE, RMSE, R²) contra los
   ensayos reales para cada combinación; sirve para retroalimentar/calibrar
   el modelo con nuevos datos de laboratorio.

Solo usa la librería estándar (math/statistics) para mantener el backend
liviano; el volumen de datos (~1.900 filas) no justifica numpy.
"""
from __future__ import annotations

import math
import statistics
from collections import defaultdict

from sqlalchemy import func, select

from .extensions import db
from .models import Aditivo, ResultadoConcreto, TipoAditivo

AGES_ESTIMATE = (3, 7, 14, 21, 28, 56, 90)

# Variables experimentales que se pueden graficar en el eje X de la dispersión.
DISPERSION_VARIABLES = ("temperatura", "humedad", "relacion_ac", "porcentaje_aditivo")
CONTROL_LABEL = "Sin aditivo"


# ── Utilidades numéricas ────────────────────────────────────────────────
def fit_log_curve(points: list[tuple[float, float]]) -> dict | None:
    """Ajusta f(t) = a + b·ln(t) por mínimos cuadrados.

    `points` = [(edad_dias, resistencia), ...]. Necesita ≥ 2 edades distintas.
    Devuelve a, b, r2 y la fórmula legible; None si no hay datos suficientes.
    """
    pts = [(math.log(t), f) for t, f in points if t > 0]
    n = len(pts)
    if n < 2 or len({x for x, _ in pts}) < 2:
        return None
    sx = sum(x for x, _ in pts)
    sy = sum(y for _, y in pts)
    sxx = sum(x * x for x, _ in pts)
    sxy = sum(x * y for x, y in pts)
    denom = n * sxx - sx * sx
    if denom == 0:
        return None
    b = (n * sxy - sx * sy) / denom
    a = (sy - b * sx) / n
    y_mean = sy / n
    ss_tot = sum((y - y_mean) ** 2 for _, y in pts)
    ss_res = sum((y - (a + b * x)) ** 2 for x, y in pts)
    r2 = 1 - ss_res / ss_tot if ss_tot > 0 else None
    return {
        "a": round(a, 4),
        "b": round(b, 4),
        "r2": round(r2, 4) if r2 is not None else None,
        "formula": f"f(t) = {a:.2f} + {b:.2f}*ln(t)",
    }


def eval_curve(curve: dict, t: float) -> float:
    return round(curve["a"] + curve["b"] * math.log(t), 2)


def porcentaje_valor(porcentaje_aplicado: str) -> float:
    """Cantidad de aditivo como número: "0.4%" → 0.4 (el catálogo la guarda como texto)."""
    try:
        return float(porcentaje_aplicado.replace("%", "").replace(",", ".").strip())
    except (AttributeError, ValueError):
        return 0.0


def tipo_aditivo_label(tipo: str, porcentaje: float) -> str:
    """El control P0 (0 %) figura como impermeabilizante en el catálogo; se reporta aparte."""
    return CONTROL_LABEL if porcentaje == 0 else tipo


def pearson(xs: list[float], ys: list[float]) -> float | None:
    """Coeficiente de correlación de Pearson; None si alguna serie no varía."""
    n = len(xs)
    if n < 2:
        return None
    mx, my = statistics.fmean(xs), statistics.fmean(ys)
    sxy = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    sxx = sum((x - mx) ** 2 for x in xs)
    syy = sum((y - my) ** 2 for y in ys)
    if sxx == 0 or syy == 0:
        return None
    return round(sxy / math.sqrt(sxx * syy), 4)


def _age_stats(rows) -> list[dict]:
    by_age: dict[int, list[float]] = defaultdict(list)
    for r in rows:
        by_age[r.edad_dias].append(r.resistencia_mpa)
    out = []
    for edad in sorted(by_age):
        vals = by_age[edad]
        out.append(
            {
                "edad_dias": edad,
                "promedio": round(statistics.fmean(vals), 2),
                "desviacion": round(statistics.stdev(vals), 2) if len(vals) > 1 else None,
                "minimo": round(min(vals), 2),
                "maximo": round(max(vals), 2),
                "num_muestras": len(vals),
            }
        )
    return out


# ── 1. Predicción ───────────────────────────────────────────────────────
def predict_strength(temperatura: int, humedad: int, relacion_ac: float, aditivo_id: int) -> dict:
    rows = db.session.scalars(
        select(ResultadoConcreto).where(
            ResultadoConcreto.temperatura == temperatura,
            ResultadoConcreto.humedad == humedad,
            ResultadoConcreto.relacion_ac == relacion_ac,
            ResultadoConcreto.aditivo_id == aditivo_id,
        )
    ).all()

    por_edad = _age_stats(rows)
    by_age = {s["edad_dias"]: s["promedio"] for s in por_edad}
    curve = fit_log_curve([(s["edad_dias"], s["promedio"]) for s in por_edad])
    estimada = {t: eval_curve(curve, t) for t in AGES_ESTIMATE} if curve else {}

    return {
        "dias_7": by_age.get(7),
        "dias_14": by_age.get(14),
        "dias_28": by_age.get(28),
        "por_edad": por_edad,
        "curva": curve,
        "curva_estimada": estimada,
        "num_muestras": len(rows),
    }


# ── 2. Rangos óptimos ───────────────────────────────────────────────────
def optimal_ranges(resistencia_objetivo: float) -> dict:
    """Combinaciones cuyo promedio a 28 días ≥ objetivo y rango de cada variable."""
    stmt = (
        select(
            ResultadoConcreto.temperatura,
            ResultadoConcreto.humedad,
            ResultadoConcreto.relacion_ac,
            ResultadoConcreto.aditivo_id,
            Aditivo.codigo,
            func.avg(ResultadoConcreto.resistencia_mpa).label("promedio"),
            func.count().label("n"),
            Aditivo.porcentaje_aplicado,
            TipoAditivo.nombre.label("tipo"),
        )
        .join(Aditivo, Aditivo.id == ResultadoConcreto.aditivo_id)
        .join(TipoAditivo, TipoAditivo.id == Aditivo.tipo_aditivo_id)
        .where(ResultadoConcreto.edad_dias == 28)
        .group_by(
            ResultadoConcreto.temperatura,
            ResultadoConcreto.humedad,
            ResultadoConcreto.relacion_ac,
            ResultadoConcreto.aditivo_id,
            Aditivo.codigo,
            Aditivo.porcentaje_aplicado,
            TipoAditivo.nombre,
        )
    )
    todas = db.session.execute(stmt).all()
    cumplen = [c for c in todas if c.promedio >= resistencia_objetivo]

    def rango(vals):
        vals = sorted(set(vals))
        return {"min": vals[0], "max": vals[-1], "valores": vals} if vals else {"min": 0, "max": 0, "valores": []}

    # Tipo y cantidad de aditivo: la cantidad solo es comparable dentro de un mismo tipo.
    pct_por_tipo: dict[str, list[float]] = defaultdict(list)
    for c in cumplen:
        pct = porcentaje_valor(c.porcentaje_aplicado)
        pct_por_tipo[tipo_aditivo_label(c.tipo, pct)].append(pct)

    rangos = {
        "temperatura": rango([c.temperatura for c in cumplen]),
        "humedad": rango([c.humedad for c in cumplen]),
        "relacion_ac": rango([c.relacion_ac for c in cumplen]),
    }
    mejores = sorted(cumplen, key=lambda c: c.promedio, reverse=True)[:10]
    return {
        "resistencia_objetivo": resistencia_objetivo,
        "total_combinaciones": len(todas),
        "combinaciones_que_cumplen": len(cumplen),
        "rangos": rangos,
        "aditivos": [
            {"tipo_aditivo": tipo, **rango(vals), "combinaciones": len(vals)}
            for tipo, vals in sorted(pct_por_tipo.items())
        ],
        "mejores": [
            {
                "temperatura": c.temperatura,
                "humedad": c.humedad,
                "relacion_ac": c.relacion_ac,
                "aditivo_id": c.aditivo_id,
                "aditivo_codigo": c.codigo,
                "tipo_aditivo": tipo_aditivo_label(c.tipo, porcentaje_valor(c.porcentaje_aplicado)),
                "porcentaje_aditivo": porcentaje_valor(c.porcentaje_aplicado),
                "promedio_28d": round(c.promedio, 2),
                "num_muestras": c.n,
            }
            for c in mejores
        ],
    }


# ── 3. Dispersión ───────────────────────────────────────────────────────
def dispersion(variable: str, edad_dias: int, tipo_aditivo: str | None = None) -> dict:
    """Ensayos individuales (resistencia vs. una variable) y tabla de dispersión.

    Por cada valor de la variable: n, promedio, desviación estándar, coeficiente
    de variación, mínimo, máximo y rango. Incluye la correlación de Pearson
    entre la variable y la resistencia.
    """
    rows = db.session.execute(
        select(
            ResultadoConcreto.temperatura,
            ResultadoConcreto.humedad,
            ResultadoConcreto.relacion_ac,
            ResultadoConcreto.resistencia_mpa,
            Aditivo.codigo,
            Aditivo.porcentaje_aplicado,
            TipoAditivo.nombre.label("tipo"),
        )
        .join(Aditivo, Aditivo.id == ResultadoConcreto.aditivo_id)
        .join(TipoAditivo, TipoAditivo.id == Aditivo.tipo_aditivo_id)
        .where(ResultadoConcreto.edad_dias == edad_dias)
        .order_by(ResultadoConcreto.id)
    ).all()

    puntos = []
    for r in rows:
        pct = porcentaje_valor(r.porcentaje_aplicado)
        tipo = tipo_aditivo_label(r.tipo, pct)
        if tipo_aditivo and tipo != tipo_aditivo:
            continue
        x = pct if variable == "porcentaje_aditivo" else getattr(r, variable)
        puntos.append(
            {
                "x": float(x),
                "y": round(r.resistencia_mpa, 2),
                "tipo_aditivo": tipo,
                "aditivo_codigo": r.codigo,
            }
        )

    by_x: dict[float, list[float]] = defaultdict(list)
    for p in puntos:
        by_x[p["x"]].append(p["y"])
    tabla = []
    for x in sorted(by_x):
        vals = by_x[x]
        prom = statistics.fmean(vals)
        desv = statistics.stdev(vals) if len(vals) > 1 else None
        tabla.append(
            {
                "valor": x,
                "num_muestras": len(vals),
                "promedio": round(prom, 2),
                "desviacion": round(desv, 2) if desv is not None else None,
                "coef_variacion": round(desv / prom * 100, 2) if desv is not None and prom else None,
                "minimo": round(min(vals), 2),
                "maximo": round(max(vals), 2),
                "rango": round(max(vals) - min(vals), 2),
            }
        )

    return {
        "variable": variable,
        "edad_dias": edad_dias,
        "tipo_aditivo": tipo_aditivo,
        "num_puntos": len(puntos),
        "correlacion": pearson([p["x"] for p in puntos], [p["y"] for p in puntos]),
        "tipos_aditivo": sorted({p["tipo_aditivo"] for p in puntos}),
        "puntos": puntos,
        "tabla": tabla,
    }


# ── 4. Calibración ──────────────────────────────────────────────────────
def calibration() -> dict:
    """Error del modelo logarítmico contra cada ensayo real, por combinación."""
    rows = db.session.scalars(select(ResultadoConcreto)).all()
    groups: dict[tuple, list] = defaultdict(list)
    for r in rows:
        groups[(r.temperatura, r.humedad, r.relacion_ac, r.aditivo_id)].append(r)

    detalle = []
    abs_errors: list[float] = []
    sq_errors: list[float] = []
    r2s: list[float] = []
    for (t, h, ac, ad), rs in sorted(groups.items()):
        stats = _age_stats(rs)
        curve = fit_log_curve([(s["edad_dias"], s["promedio"]) for s in stats])
        if not curve:
            continue
        errs = [r.resistencia_mpa - eval_curve(curve, r.edad_dias) for r in rs]
        mae = sum(abs(e) for e in errs) / len(errs)
        rmse = math.sqrt(sum(e * e for e in errs) / len(errs))
        abs_errors.extend(abs(e) for e in errs)
        sq_errors.extend(e * e for e in errs)
        if curve["r2"] is not None:
            r2s.append(curve["r2"])
        detalle.append(
            {
                "temperatura": t, "humedad": h, "relacion_ac": ac, "aditivo_id": ad,
                "a": curve["a"], "b": curve["b"], "r2": curve["r2"],
                "mae": round(mae, 3), "rmse": round(rmse, 3), "num_muestras": len(rs),
            }
        )

    return {
        "modelo": "f(t) = a + b*ln(t), ajuste por minimos cuadrados sobre promedios 7/14/28 d",
        "combinaciones": len(detalle),
        "mae_global": round(sum(abs_errors) / len(abs_errors), 3) if abs_errors else 0.0,
        "rmse_global": round(math.sqrt(sum(sq_errors) / len(sq_errors)), 3) if sq_errors else 0.0,
        "r2_promedio": round(statistics.fmean(r2s), 4) if r2s else None,
        "detalle": detalle,
    }
