"""Importación por lote de ensayos desde texto CSV.

Formato (encabezado obligatorio, delimitador `;` o `,`, decimales con punto
o con coma si el delimitador es `;`):

    temperatura;humedad;relacion_ac;edad_dias;resistencia_mpa;aditivo;tipo_estructura;fecha_ensayo;observaciones
    25;70;0.45;28;48.3;PP2;Puentes;2026-09-20;Cilindro 3

`aditivo` acepta el código (P0…PP3) o el id; `tipo_estructura` acepta
Puentes, Tuneles/Túneles o Muros. `fecha_ensayo` (AAAA-MM-DD) y
`observaciones` son opcionales. Se valida todo el archivo antes de insertar:
si alguna línea falla no se guarda nada.
"""
from __future__ import annotations

import csv
import io
import unicodedata

from marshmallow import ValidationError
from sqlalchemy import select

from .extensions import db
from .models import Aditivo
from .schemas import ResultadoInputSchema

REQUIRED = ("temperatura", "humedad", "relacion_ac", "edad_dias", "resistencia_mpa", "aditivo", "tipo_estructura")
ALIASES = {
    "relacion_a_c": "relacion_ac",
    "a_c": "relacion_ac",
    "edad": "edad_dias",
    "resistencia": "resistencia_mpa",
    "aditivo_id": "aditivo",
    "aditivo_codigo": "aditivo",
    "estructura": "tipo_estructura",
    "fecha": "fecha_ensayo",
}
MAX_LINES = 5000


def _key(value: str) -> str:
    """Normaliza encabezados y códigos: minúsculas, sin tildes ni espacios."""
    value = unicodedata.normalize("NFKD", value.strip().lower())
    value = "".join(c for c in value if not unicodedata.combining(c))
    return value.replace(" ", "_").replace("/", "_")


def _estructura(value: str) -> str:
    k = _key(value)
    if k.startswith("puente"):
        return "Puentes"
    if k.startswith("tunel"):
        return "Tuneles"
    if k.startswith("muro"):
        return "Muros"
    return value.strip()


def parse_csv(text: str) -> tuple[list[dict], list[dict]]:
    """Devuelve (filas válidas listas para insertar, errores por línea)."""
    text = text.lstrip("﻿").strip()
    first = text.splitlines()[0] if text else ""
    delimiter = ";" if first.count(";") >= first.count(",") else ","
    reader = csv.reader(io.StringIO(text), delimiter=delimiter)

    header = [ALIASES.get(_key(h), _key(h)) for h in next(reader, [])]
    missing = [c for c in REQUIRED if c not in header]
    if missing:
        return [], [{"linea": 1, "mensaje": f"Faltan columnas: {', '.join(missing)}"}]

    aditivos = {a.codigo.upper(): a.id for a in db.session.scalars(select(Aditivo))}
    aditivo_ids = set(aditivos.values())
    schema = ResultadoInputSchema()
    rows, errors = [], []
    for linea, values in enumerate(reader, start=2):
        if not any(v.strip() for v in values):
            continue
        if linea - 1 > MAX_LINES:
            errors.append({"linea": linea, "mensaje": f"Máximo {MAX_LINES} ensayos por archivo"})
            break
        raw = {col: (values[i].strip() if i < len(values) else "") for i, col in enumerate(header)}
        if delimiter == ";":
            for col in ("relacion_ac", "resistencia_mpa"):
                raw[col] = raw.get(col, "").replace(",", ".")

        aditivo = raw.pop("aditivo", "").upper()
        aditivo_id = aditivos.get(aditivo) or (int(aditivo) if aditivo.isdigit() else None)
        if aditivo_id not in aditivo_ids:
            errors.append({"linea": linea, "mensaje": f"Aditivo desconocido: '{aditivo}'"})
            continue

        data = {
            "temperatura": raw.get("temperatura"),
            "humedad": raw.get("humedad"),
            "relacion_ac": raw.get("relacion_ac"),
            "edad_dias": raw.get("edad_dias"),
            "resistencia_mpa": raw.get("resistencia_mpa"),
            "aditivo_id": aditivo_id,
            "tipo_estructura": _estructura(raw.get("tipo_estructura", "")),
            "fecha_ensayo": raw.get("fecha_ensayo") or None,
            "observaciones": raw.get("observaciones") or None,
        }
        try:
            rows.append(schema.load(data))
        except ValidationError as exc:
            detalle = "; ".join(f"{campo}: {' '.join(msgs)}" for campo, msgs in exc.messages.items())
            errors.append({"linea": linea, "mensaje": detalle})

    if not rows and not errors:
        errors.append({"linea": 1, "mensaje": "El archivo no tiene ensayos"})
    return rows, errors
