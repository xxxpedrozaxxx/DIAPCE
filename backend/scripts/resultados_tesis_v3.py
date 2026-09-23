"""Cifras de ANOVA, regresión, optimización y dosificación para el documento de grado.

    python scripts/resultados_tesis_v3.py salida.json
"""
from __future__ import annotations

import json
import sys

from app import create_app
from app.estadistica import anova, optimizar, regresion
from app.mixtures_logic import proporciones


def main(out: str) -> None:
    app = create_app()
    with app.app_context():
        modelo = regresion()
        modelo.pop("_beta")
        escenarios = []
        for fc in (21, 28, 35, 42):
            r = optimizar(fc, 27, 70, "Puentes")
            control = next(a for a in r["alternativas"] if a["dosis_pct"] == 0)
            escenarios.append({
                "fc": fc, "fcr": r["resistencia_requerida"], "s": r["desviacion_estandar"],
                "mejor": r["alternativas"][0], "control": control, "advertencias": r["advertencias"],
            })
        extrapolacion = optimizar(28, 26, 77, "Puentes")
        dosificaciones = {
            e: proporciones(0.45, e, 6)["diseno"] for e in ("Muros", "Puentes", "Tuneles")
        }
        json.dump({
            "anova": {e: anova(e) for e in (7, 14, 28)},
            "modelo": modelo,
            "escenarios": escenarios,
            "villavicencio": {"advertencias": extrapolacion["advertencias"],
                              "mejor": extrapolacion["alternativas"][0],
                              "fcr": extrapolacion["resistencia_requerida"]},
            "dosificaciones": dosificaciones,
        }, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1, default=str)
        print(f"[OK] {out}")


if __name__ == "__main__":
    main(sys.argv[1])
