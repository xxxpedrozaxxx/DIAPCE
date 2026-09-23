"""Exporta el esquema de PostgreSQL a backend/schema.sql (DDL de referencia).

    python scripts/export_schema.py

Usa pg_dump --schema-only con las credenciales de DATABASE_URL y quita las
líneas de configuración de la sesión para dejar solo el DDL.
"""
from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
from glob import glob
from pathlib import Path
from urllib.parse import urlparse

from dotenv import load_dotenv

BACKEND = Path(__file__).resolve().parent.parent
SKIP = ("--", "SET ", "SELECT pg_catalog", "\\restrict", "\\unrestrict")
HEADER = """-- Esquema DIAPCE v6 (PostgreSQL), generado con scripts/export_schema.py (pg_dump --schema-only).
-- Tablas: users, tipos_estructura, materials, tipos_aditivo, productos, aditivos,
-- resultados_concreto, mixtures, mixture_materials, projects, calibraciones,
-- schema_migrations.

"""


def pg_dump_path() -> str:
    found = shutil.which("pg_dump")
    if found:
        return found
    candidates = sorted(glob(r"C:\Program Files\PostgreSQL\*\bin\pg_dump.exe"))
    if not candidates:
        sys.exit("No se encontró pg_dump")
    return candidates[-1]


def main() -> None:
    load_dotenv(BACKEND / ".env")
    url = urlparse(os.environ["DATABASE_URL"].replace("postgresql+psycopg2", "postgresql"))
    env = {**os.environ, "PGPASSWORD": url.password or ""}
    ddl = subprocess.run(
        [pg_dump_path(), "-U", url.username, "-h", url.hostname, "-p", str(url.port or 5432),
         "-d", url.path.lstrip("/"), "--schema-only", "--no-owner", "--no-privileges"],
        env=env, check=True, capture_output=True, text=True, encoding="utf-8",
    ).stdout
    lines = [line for line in ddl.splitlines() if not line.startswith(SKIP)]
    text = re.sub(r"\n{3,}", "\n\n", "\n".join(lines)).strip() + "\n"
    (BACKEND / "schema.sql").write_text(HEADER + text, encoding="utf-8")
    print(f"[OK] schema.sql ({text.count('CREATE TABLE')} tablas)")


if __name__ == "__main__":
    main()
