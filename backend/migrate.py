"""Aplica las migraciones SQL pendientes de migrations/ en orden.

    python migrate.py

Cada archivo se registra en la tabla `schema_migrations`, así que ejecutar
el comando varias veces es seguro. Una base nueva creada con `seed.py` ya
tiene el esquema final; las migraciones son para bases existentes.
"""
from __future__ import annotations

from pathlib import Path

from sqlalchemy import text

from app import create_app
from app.extensions import db

MIGRATIONS_DIR = Path(__file__).resolve().parent / "migrations"


def migrate() -> list[str]:
    db.session.execute(
        text(
            "CREATE TABLE IF NOT EXISTS schema_migrations ("
            " nombre varchar(128) PRIMARY KEY,"
            " aplicada_en timestamp without time zone NOT NULL DEFAULT now())"
        )
    )
    aplicadas = set(db.session.scalars(text("SELECT nombre FROM schema_migrations")))
    nuevas = []
    for path in sorted(MIGRATIONS_DIR.glob("*.sql")):
        if path.name in aplicadas:
            continue
        # exec_driver_sql envía el archivo completo (incluye bloques DO $$ ... $$).
        db.session.connection().exec_driver_sql(path.read_text(encoding="utf-8"))
        db.session.execute(
            text("INSERT INTO schema_migrations (nombre) VALUES (:n)"), {"n": path.name}
        )
        nuevas.append(path.name)
    db.session.commit()
    return nuevas


if __name__ == "__main__":
    app = create_app()
    with app.app_context():
        aplicadas = migrate()
        print("\n".join(f"[OK] {n}" for n in aplicadas) or "[--] Sin migraciones pendientes")
