"""Extrae las cifras del capítulo de resultados del trabajo de grado.

    python scripts/resultados_tesis.py salida.json

Usa las mismas funciones que la API (app/analysis.py) sobre la base
configurada en .env, así que las cifras del documento coinciden con lo que
muestra la aplicación.
"""
from __future__ import annotations

import json
import statistics
import sys
from collections import Counter, defaultdict

from sqlalchemy import func, select

from app import create_app
from app.analysis import calibration, dispersion, optimal_ranges, porcentaje_valor, tipo_aditivo_label
from app.extensions import db
from app.models import Aditivo, ResultadoConcreto, TipoAditivo


def main(out: str) -> None:
    app = create_app()
    with app.app_context():
        rows = db.session.execute(
            select(ResultadoConcreto, Aditivo.codigo, Aditivo.porcentaje_aplicado, TipoAditivo.nombre)
            .join(Aditivo, Aditivo.id == ResultadoConcreto.aditivo_id)
            .join(TipoAditivo, TipoAditivo.id == Aditivo.tipo_aditivo_id)
        ).all()
        ensayos = [r[0] for r in rows]

        por_edad = defaultdict(list)
        for r in ensayos:
            por_edad[r.edad_dias].append(r.resistencia_mpa)
        dataset = {
            "total": len(ensayos),
            "combinaciones": len({(r.temperatura, r.humedad, r.relacion_ac, r.aditivo_id) for r in ensayos}),
            "por_edad": {
                e: {"n": len(v), "media": round(statistics.fmean(v), 2), "desv": round(statistics.stdev(v), 2),
                    "min": round(min(v), 2), "max": round(max(v), 2)}
                for e, v in sorted(por_edad.items())
            },
            "temperatura": dict(sorted(Counter(r.temperatura for r in ensayos).items())),
            "humedad": dict(sorted(Counter(r.humedad for r in ensayos).items())),
            "relacion_ac": dict(sorted(Counter(r.relacion_ac for r in ensayos).items())),
            "aditivo": dict(sorted(Counter(c for _, c, _, _ in rows).items())),
            "origen": dict(Counter(r.origen for r in ensayos)),
        }

        # Promedio a 28 días por aditivo y por temperatura × humedad.
        por_aditivo = defaultdict(list)
        th = defaultdict(list)
        for r, codigo, pct, tipo in rows:
            if r.edad_dias == 28:
                por_aditivo[(codigo, tipo_aditivo_label(tipo, porcentaje_valor(pct)), pct)].append(r.resistencia_mpa)
                th[(r.temperatura, r.humedad)].append(r.resistencia_mpa)
        aditivos_28 = [
            {"codigo": c, "tipo": t, "dosis": p, "n": len(v), "media": round(statistics.fmean(v), 2),
             "desv": round(statistics.stdev(v), 2)}
            for (c, t, p), v in sorted(por_aditivo.items())
        ]
        temp_hum_28 = [
            {"temperatura": t, "humedad": h, "n": len(v), "media": round(statistics.fmean(v), 2)}
            for (t, h), v in sorted(th.items())
        ]

        disp = {}
        for var in ("temperatura", "humedad", "relacion_ac", "porcentaje_aditivo"):
            disp[var] = {}
            for edad in (7, 14, 28):
                d = dispersion(var, edad)
                d.pop("puntos")
                disp[var][edad] = d
        disp_tipo = {
            tipo: {k: v for k, v in dispersion("porcentaje_aditivo", 28, tipo).items() if k != "puntos"}
            for tipo in ("Impermeabilizante", "Plastificante")
        }
        puntos_ac_28 = [(p["x"], p["y"], p["tipo_aditivo"]) for p in dispersion("relacion_ac", 28)["puntos"]]

        rangos = {obj: optimal_ranges(obj) for obj in (35, 40, 45, 50, 55)}
        cal = calibration()
        cal.pop("detalle")

        json.dump({
            "dataset": dataset,
            "aditivos_28": aditivos_28,
            "temp_hum_28": temp_hum_28,
            "dispersion": disp,
            "dispersion_por_tipo": disp_tipo,
            "puntos_ac_28": puntos_ac_28,
            "rangos": rangos,
            "calibracion": cal,
        }, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1, default=str)
        print(f"[OK] {out}")


if __name__ == "__main__":
    main(sys.argv[1])
