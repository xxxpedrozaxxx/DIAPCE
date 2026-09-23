"""Análisis estadístico inferencial y optimización de la dosificación.

1. `anova(edad)` — análisis de varianza de la resistencia con los factores
   temperatura, humedad, relación a/c y aditivo, más las interacciones
   temperatura × humedad y a/c × aditivo. Como el diseño no es factorial
   completo (desbalanceado), las sumas de cuadrados son de tipo II: cada
   efecto se ajusta por los demás efectos principales, comparando el modelo
   con y sin él (Montgomery, 2017).
2. `regresion()` — modelo de regresión lineal múltiple sobre todos los
   ensayos:
       f'c = b0 + b1·ln(t) + b2·T + b3·T² + b4·HR + b5·a/c + b6·Dimp + b7·Dplast
             + b8·ln(t)·(a/c)
   T² permite el óptimo de temperatura y ln(t) el desarrollo en el tiempo.
   Se valida dejando fuera **combinaciones completas**, que es el caso de uso
   real: predecir condiciones que no se han ensayado.
3. `optimizar(...)` — dado el clima de la obra, el tipo de estructura y la
   resistencia especificada f'c, busca la relación a/c y el aditivo que
   alcanzan la resistencia promedio requerida f'cr (ACI 318) con el menor
   contenido de cemento, y dosifica cada alternativa por ACI 211.1.
"""
from __future__ import annotations

import math
import statistics
from collections import defaultdict

import numpy as np
from scipy import stats
from sqlalchemy import select

from .analysis import porcentaje_valor, tipo_aditivo_label
from .extensions import db
from .models import Aditivo, ResultadoConcreto, TipoAditivo

RANGO_T = (10, 32)
RANGO_HR = (20, 70)
RANGO_AC = (0.40, 0.50)
TERMINOS = ["Intercepto", "ln(t)", "T", "T²", "HR", "a/c", "Dosis impermeabilizante",
            "Dosis plastificante", "ln(t)·a/c"]


def _ensayos(edad: int | None = None) -> list[dict]:
    stmt = (
        select(ResultadoConcreto, Aditivo.codigo, Aditivo.porcentaje_aplicado, TipoAditivo.nombre)
        .join(Aditivo, Aditivo.id == ResultadoConcreto.aditivo_id)
        .join(TipoAditivo, TipoAditivo.id == Aditivo.tipo_aditivo_id)
    )
    if edad:
        stmt = stmt.where(ResultadoConcreto.edad_dias == edad)
    out = []
    for r, codigo, pct, tipo in db.session.execute(stmt):
        dosis = porcentaje_valor(pct)
        tipo = tipo_aditivo_label(tipo, dosis)
        out.append({
            "t": r.edad_dias, "T": r.temperatura, "HR": r.humedad, "ac": r.relacion_ac,
            "codigo": codigo, "di": dosis if tipo == "Impermeabilizante" else 0.0,
            "dp": dosis if tipo == "Plastificante" else 0.0, "y": r.resistencia_mpa,
            "combo": (r.temperatura, r.humedad, r.relacion_ac, r.aditivo_id),
        })
    return out


# ── ANOVA ───────────────────────────────────────────────────────────────
def _dummies(valores: list, drop_first: bool = True) -> np.ndarray:
    niveles = sorted(set(valores))
    if drop_first:
        niveles = niveles[1:]
    return np.array([[1.0 if v == n else 0.0 for n in niveles] for v in valores]).reshape(len(valores), -1)


def _sse(X: np.ndarray, y: np.ndarray) -> tuple[float, int]:
    beta, *_ = np.linalg.lstsq(X, y, rcond=None)
    r = y - X @ beta
    return float(r @ r), int(np.linalg.matrix_rank(X))


def anova(edad: int = 28) -> dict:
    datos = _ensayos(edad)
    y = np.array([d["y"] for d in datos])
    n = len(y)
    unos = np.ones((n, 1))
    factores = {
        "Temperatura": [d["T"] for d in datos],
        "Humedad relativa": [d["HR"] for d in datos],
        "Relación a/c": [d["ac"] for d in datos],
        "Aditivo": [d["codigo"] for d in datos],
    }
    interacciones = {
        "Temperatura × Humedad": [(d["T"], d["HR"]) for d in datos],
        "Relación a/c × Aditivo": [(d["ac"], d["codigo"]) for d in datos],
    }
    principales = {k: _dummies(v) for k, v in factores.items()}
    celdas = {k: _dummies(v, drop_first=False) for k, v in interacciones.items()}

    def modelo(excluir: str | None = None, con_interacciones: tuple[str, ...] = ()) -> np.ndarray:
        partes = [unos] + [m for k, m in principales.items() if k != excluir]
        partes += [celdas[k] for k in con_interacciones]
        return np.hstack(partes)

    todas = tuple(interacciones)
    sse_full, rank_full = _sse(modelo(con_interacciones=todas), y)
    gl_res = n - rank_full
    cme = sse_full / gl_res
    sse_main, rank_main = _sse(modelo(), y)
    sct = float(((y - y.mean()) ** 2).sum())

    filas = []

    def fila(nombre, sc, gl):
        f = (sc / gl) / cme if gl else None
        filas.append({
            "fuente": nombre, "sc": round(sc, 2), "gl": gl, "cm": round(sc / gl, 2) if gl else None,
            "f": round(f, 2) if f is not None else None,
            "p": float(stats.f.sf(f, gl, gl_res)) if f is not None else None,
            "eta2_parcial": round(sc / (sc + sse_full), 4),
        })

    for nombre in factores:
        sse_red, rank_red = _sse(modelo(excluir=nombre), y)
        fila(nombre, sse_red - sse_main, rank_main - rank_red)
    for nombre in interacciones:
        otras = tuple(k for k in todas if k != nombre)
        sse_red, rank_red = _sse(modelo(con_interacciones=otras), y)
        fila(nombre, sse_red - sse_full, rank_full - rank_red)

    medias = {
        nombre: [
            {"nivel": nivel, "n": len(vals), "media": round(statistics.fmean(vals), 2)}
            for nivel, vals in sorted(_agrupar(valores, y).items())
        ]
        for nombre, valores in factores.items()
    }
    return {
        "edad_dias": edad,
        "n": n,
        "metodo": "ANOVA con sumas de cuadrados tipo II (diseño desbalanceado)",
        "r2": round(1 - sse_full / sct, 4),
        "filas": filas,
        "residual": {"sc": round(sse_full, 2), "gl": gl_res, "cm": round(cme, 3)},
        "total": {"sc": round(sct, 2), "gl": n - 1},
        "medias": medias,
    }


def _agrupar(valores, y) -> dict:
    grupos = defaultdict(list)
    for v, yi in zip(valores, y):
        grupos[v].append(float(yi))
    return grupos


# ── Regresión múltiple ─────────────────────────────────────────────────
def _fila_x(t: float, T: float, HR: float, ac: float, di: float, dp: float) -> list[float]:
    lt = math.log(t)
    return [1.0, lt, T, T * T, HR, ac, di, dp, lt * ac]


def _metricas(y: np.ndarray, pred: np.ndarray) -> dict:
    e = y - pred
    return {
        "n": int(len(y)),
        "mae": round(float(np.abs(e).mean()), 3),
        "rmse": round(float(math.sqrt((e ** 2).mean())), 3),
        "mape": round(float((np.abs(e) / y).mean() * 100), 2),
    }


def regresion(validar: bool = True) -> dict:
    datos = _ensayos()
    X = np.array([_fila_x(d["t"], d["T"], d["HR"], d["ac"], d["di"], d["dp"]) for d in datos])
    y = np.array([d["y"] for d in datos])
    n, k = X.shape
    beta, *_ = np.linalg.lstsq(X, y, rcond=None)
    pred = X @ beta
    sse = float(((y - pred) ** 2).sum())
    sct = float(((y - y.mean()) ** 2).sum())
    cme = sse / (n - k)
    ee = np.sqrt(np.diag(cme * np.linalg.inv(X.T @ X)))
    tval = beta / ee
    pval = 2 * stats.t.sf(np.abs(tval), n - k)
    r2 = 1 - sse / sct
    resultado = {
        "ecuacion": "f'c = b0 + b1·ln(t) + b2·T + b3·T² + b4·HR + b5·a/c + b6·Dimp + b7·Dplast + b8·ln(t)·a/c",
        "n": n,
        "r2": round(r2, 4),
        "r2_ajustado": round(1 - (1 - r2) * (n - 1) / (n - k), 4),
        "rmse": round(math.sqrt(sse / n), 3),
        "coeficientes": [
            {"termino": t, "valor": float(b), "error_estandar": float(e), "t": float(tv), "p": float(p)}
            for t, b, e, tv, p in zip(TERMINOS, beta, ee, tval, pval)
        ],
        "rangos_validos": {"temperatura": RANGO_T, "humedad": RANGO_HR, "relacion_ac": RANGO_AC},
        "_beta": beta,
    }
    if validar:
        # Validación dejando fuera cada combinación completa (todas sus edades).
        grupos = defaultdict(list)
        for i, d in enumerate(datos):
            grupos[d["combo"]].append(i)
        pred_cv = np.empty(n)
        for idx in grupos.values():
            mask = np.ones(n, bool)
            mask[idx] = False
            b, *_ = np.linalg.lstsq(X[mask], y[mask], rcond=None)
            pred_cv[idx] = X[idx] @ b
        edades = np.array([d["t"] for d in datos])
        resultado["validacion"] = {
            "metodo": "Validación cruzada dejando fuera una combinación completa (91 pliegues)",
            **_metricas(y, pred_cv),
            "por_edad": [{"edad_dias": int(e), **_metricas(y[edades == e], pred_cv[edades == e])}
                         for e in sorted(set(edades))],
        }
    return resultado


def predecir(beta, t, T, HR, ac, di=0.0, dp=0.0) -> float:
    return float(np.array(_fila_x(t, T, HR, ac, di, dp)) @ beta)


# ── Optimización ───────────────────────────────────────────────────────
def desviacion_agrupada(edad: int = 28) -> float:
    """Desviación estándar agrupada entre cilindros de una misma combinación."""
    grupos = defaultdict(list)
    for d in _ensayos(edad):
        grupos[d["combo"]].append(d["y"])
    num = sum((len(v) - 1) * statistics.variance(v) for v in grupos.values() if len(v) > 1)
    den = sum(len(v) - 1 for v in grupos.values() if len(v) > 1)
    return math.sqrt(num / den)


def resistencia_requerida(fc: float, s: float) -> float:
    """Resistencia promedio requerida f'cr (ACI 318-19, 26.4.3 / Tabla 5.3.2.1)."""
    if fc <= 35:
        return max(fc + 1.34 * s, fc + 2.33 * s - 3.5)
    return max(fc + 1.34 * s, 0.90 * fc + 2.33 * s)


def optimizar(fc: float, temperatura: float, humedad: float, tipo_estructura: str, edad: int = 28) -> dict:
    from .mixtures_logic import mixture_cost, proporciones  # evita import circular

    modelo = regresion(validar=False)
    beta = modelo["_beta"]
    s = desviacion_agrupada(28)
    fcr = resistencia_requerida(fc, s)

    advertencias = []
    if not RANGO_T[0] <= temperatura <= RANGO_T[1]:
        advertencias.append(f"La temperatura {temperatura:g} °C está fuera del rango ensayado "
                            f"({RANGO_T[0]}–{RANGO_T[1]} °C): la predicción es una extrapolación.")
    if not RANGO_HR[0] <= humedad <= RANGO_HR[1]:
        advertencias.append(f"La humedad {humedad:g} % está fuera del rango ensayado "
                            f"({RANGO_HR[0]}–{RANGO_HR[1]} %): la predicción es una extrapolación.")

    pasos = [round(RANGO_AC[1] - i * 0.01, 2) for i in range(int(round((RANGO_AC[1] - RANGO_AC[0]) / 0.01)) + 1)]
    alternativas = []
    for aditivo in db.session.scalars(select(Aditivo).order_by(Aditivo.id)):
        dosis = porcentaje_valor(aditivo.porcentaje_aplicado)
        tipo = tipo_aditivo_label(aditivo.tipo_aditivo.nombre, dosis)
        di = dosis if tipo == "Impermeabilizante" else 0.0
        dp = dosis if tipo == "Plastificante" else 0.0
        # La mayor a/c que alcanza f'cr usa menos cemento.
        elegido = next((ac for ac in pasos if predecir(beta, edad, temperatura, humedad, ac, di, dp) >= fcr), None)
        ac = elegido if elegido is not None else RANGO_AC[0]
        pred = predecir(beta, edad, temperatura, humedad, ac, di, dp)
        p = proporciones(ac, tipo_estructura, aditivo.id)
        alternativas.append({
            "aditivo_id": aditivo.id,
            "aditivo_codigo": aditivo.codigo,
            "tipo_aditivo": tipo,
            "dosis_pct": dosis,
            "relacion_ac": ac,
            "prediccion": round(pred, 2),
            "margen": round(pred - fcr, 2),
            "factible": elegido is not None,
            "cemento": p["diseno"]["cemento"],
            "costo_referencia": mixture_cost(p["filas"]),
            "materiales": [{"nombre": m.name, "unidad": m.unit, "cantidad": q} for m, q in p["filas"]],
            "descripcion": p["descripcion"],
        })

    alternativas.sort(key=lambda a: (not a["factible"], a["cemento"] if a["factible"] else -a["prediccion"],
                                     a["dosis_pct"]))
    if not any(a["factible"] for a in alternativas):
        advertencias.append(f"Ninguna combinación dentro del rango ensayado (a/c {RANGO_AC[0]:.2f}–{RANGO_AC[1]:.2f}) "
                            f"alcanza f'cr = {fcr:.1f} MPa en estas condiciones.")
    return {
        "resistencia_especificada": fc,
        "resistencia_requerida": round(fcr, 2),
        "desviacion_estandar": round(s, 2),
        "condiciones": {"temperatura": temperatura, "humedad": humedad, "tipo_estructura": tipo_estructura,
                        "edad_dias": edad},
        "criterio": "Menor contenido de cemento que alcanza f'cr; a/c limitada al rango ensayado.",
        "modelo": {"r2": modelo["r2"], "rmse": modelo["rmse"]},
        "advertencias": advertencias,
        "alternativas": alternativas,
    }
