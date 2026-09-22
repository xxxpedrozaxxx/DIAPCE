"""Crea el esquema y carga los datos de semilla.

    python seed.py            # crea tablas si no existen y siembra (idempotente)
    python seed.py --reset    # borra y recrea todas las tablas antes de sembrar

Datos: 3 tipos de estructura, 24 materiales, 2 tipos de aditivo, 3 productos,
7 aditivos y los ensayos de ../lib/data/csv_datos_1.1.csv (delimitador ';').
Port de _insertDefaultMaterials / _insertExperimentalData / _loadCSVData de
lib/core/database_helper.dart.
"""
from __future__ import annotations

import csv
import sys
from pathlib import Path

from sqlalchemy import func, select, text

from app import create_app
from app.extensions import db
from app.models import (
    Aditivo,
    Material,
    Producto,
    ResultadoConcreto,
    TipoAditivo,
    TipoEstructura,
)

CSV_PATH = Path(__file__).resolve().parent.parent / "lib" / "data" / "csv_datos_1.1.csv"

TIPOS_ESTRUCTURA = [
    ("Puentes", "Puentes"),
    ("Tuneles", "Túneles"),
    ("Muros", "Muros de contención"),
]

MATERIALS = [
    # Cementos
    ("Cemento Portland", "kg", 3.15, 8.50, "Cemento Portland tipo I"),
    ("Cemento Portland Tipo II", "kg", 3.15, 9.00, "Cemento Portland tipo II resistente a sulfatos"),
    ("Cemento de Alta Resistencia", "kg", 3.20, 12.00, "Cemento para concretos de alta resistencia"),
    # Agregados
    ("Agua", "L", 1.0, 0.002, "Agua potable para mezcla"),
    ("Arena", "kg", 2.65, 0.25, "Arena fina para construcción"),
    ("Arena Gruesa", "kg", 2.70, 0.28, "Arena gruesa para concreto"),
    ("Grava", "kg", 2.70, 0.20, "Grava triturada 19mm"),
    ("Grava Fina", "kg", 2.68, 0.22, "Grava triturada 12mm"),
    ("Piedra Pómez", "kg", 1.20, 0.35, "Agregado ligero volcánico"),
    # Aditivos
    ("Aditivo Plastificante", "L", 1.05, 15.00, "Aditivo reductor de agua"),
    ("Aditivo Superplastificante", "L", 1.08, 25.00, "Aditivo de alto rango reductor de agua"),
    ("Aditivo Acelerante", "L", 1.12, 18.00, "Acelera el fraguado del concreto"),
    ("Aditivo Retardante", "L", 1.06, 16.00, "Retarda el fraguado del concreto"),
    ("Aditivo Incorporador de Aire", "L", 1.02, 20.00, "Incorpora burbujas de aire microscópicas"),
    # Fibras y refuerzos
    ("Fibra de Acero", "kg", 7.85, 25.00, "Fibras de acero para refuerzo"),
    ("Fibra de Polipropileno", "kg", 0.91, 35.00, "Fibras sintéticas para control de fisuras"),
    ("Fibra de Vidrio", "kg", 2.50, 45.00, "Fibras de vidrio resistentes a álcalis"),
    ("Fibra de Carbono", "kg", 1.60, 120.00, "Fibras de carbono de alta resistencia"),
    # Puzolanas y adiciones
    ("Ceniza Volante", "kg", 2.30, 3.50, "Puzolana artificial de centrales térmicas"),
    ("Microsílice", "kg", 2.20, 15.00, "Puzolana de alta reactividad"),
    ("Escoria de Alto Horno", "kg", 2.85, 5.00, "Adición mineral siderúrgica"),
    # Especiales
    ("Látex Estireno-Butadieno", "L", 1.01, 28.00, "Modificador polimérico"),
    ("Resina Epoxi", "kg", 1.15, 85.00, "Resina para reparaciones estructurales"),
    ("Expansor No Metálico", "kg", 1.50, 22.00, "Agente expansor compensador de retracción"),
]

TIPOS_ADITIVO = [(1, "Impermeabilizante"), (2, "Plastificante")]
PRODUCTOS = [
    (1, "Control / Sin Aditivo", "N/A"),
    (2, "Euco Vandex AM 10I", "Euco"),
    (3, "Sika® Plastiment® AP", "Sika"),
]
ADITIVOS = [
    (1, "P0", "0%", 1, 1),
    (2, "P1", "2%", 1, 2),
    (3, "P2", "3%", 1, 2),
    (4, "P3", "4%", 1, 2),
    (5, "PP1", "0.2%", 2, 3),
    (6, "PP2", "0.4%", 2, 3),
    (7, "PP3", "0.6%", 2, 3),
]


def _sync_sequence(table: str) -> None:
    """Tras insertar con id explícito, alinea la secuencia SERIAL de Postgres."""
    if db.engine.dialect.name != "postgresql":
        return
    db.session.execute(
        text(f"SELECT setval(pg_get_serial_sequence('{table}', 'id'), COALESCE(MAX(id), 1)) FROM {table}")
    )


def seed_catalogs() -> None:
    if db.session.scalar(select(func.count()).select_from(TipoEstructura)) == 0:
        db.session.add_all(TipoEstructura(codigo=c, nombre=n) for c, n in TIPOS_ESTRUCTURA)
    if db.session.scalar(select(func.count()).select_from(Material)) == 0:
        db.session.add_all(
            Material(name=n, unit=u, density=d, cost_per_unit=c, description=desc)
            for n, u, d, c, desc in MATERIALS
        )
    if db.session.scalar(select(func.count()).select_from(TipoAditivo)) == 0:
        db.session.add_all(TipoAditivo(id=i, nombre=n) for i, n in TIPOS_ADITIVO)
        db.session.add_all(Producto(id=i, nombre_producto=n, marca=m) for i, n, m in PRODUCTOS)
        db.session.flush()
        db.session.add_all(
            Aditivo(id=i, codigo=c, porcentaje_aplicado=p, tipo_aditivo_id=t, producto_id=pr)
            for i, c, p, t, pr in ADITIVOS
        )
        db.session.flush()
        for table in ("tipos_aditivo", "productos", "aditivos"):
            _sync_sequence(table)
    db.session.commit()


def seed_csv() -> int:
    if db.session.scalar(select(func.count()).select_from(ResultadoConcreto)) > 0:
        return 0
    with CSV_PATH.open(newline="", encoding="utf-8") as fh:
        reader = csv.reader(fh, delimiter=";")
        next(reader)  # encabezado: ID;Temperatura;Humedad;Relacion_a_c;Edad;Resistencia;Aditivo_id
        rows = [
            {
                "id": int(r[0]),
                "temperatura": int(r[1]),
                "humedad": int(r[2]),
                "relacion_ac": float(r[3]),
                "edad_dias": int(r[4]),
                "resistencia_mpa": float(r[5]),
                "aditivo_id": int(r[6]),
            }
            for r in reader
            if len(r) >= 7 and r[0].strip()
        ]
    db.session.execute(ResultadoConcreto.__table__.insert(), rows)
    _sync_sequence("resultados_concreto")
    db.session.commit()
    return len(rows)


def main(reset: bool) -> None:
    app = create_app()
    with app.app_context():
        if reset:
            db.drop_all()
            print("[OK] Tablas eliminadas")
        db.create_all()
        print("[OK] Esquema verificado/creado")
        seed_catalogs()
        print("[OK] Catálogos (tipos_estructura, materials, tipos_aditivo, productos, aditivos)")
        n = seed_csv()
        print(f"[OK] resultados_concreto: {n} filas insertadas" if n else "[--] resultados_concreto ya tenía datos")


if __name__ == "__main__":
    main(reset="--reset" in sys.argv)
