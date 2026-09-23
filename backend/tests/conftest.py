"""Fixtures de pytest.

Las pruebas corren contra una base PostgreSQL aparte (`diapce_test`), nunca
contra la de desarrollo. Se recrea al inicio de la sesión con el esquema
completo, los catálogos y los 1.872 ensayos del CSV.

    TEST_DATABASE_URL=postgresql+psycopg2://diapce:diapce@localhost:5432/diapce_test
"""
from __future__ import annotations

import os
import sys
import uuid
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))

TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL", "postgresql+psycopg2://diapce:diapce@localhost:5432/diapce_test"
)
# create_app() usa DATABASE_URL si existe; load_dotenv no la sobrescribe.
os.environ["DATABASE_URL"] = TEST_DATABASE_URL

from sqlalchemy import text  # noqa: E402

from app import create_app  # noqa: E402
from app.extensions import db  # noqa: E402
from migrate import migrate  # noqa: E402
from seed import seed_catalogs, seed_csv  # noqa: E402


@pytest.fixture(scope="session")
def app():
    if not TEST_DATABASE_URL.rstrip("/").endswith("_test"):
        pytest.exit("TEST_DATABASE_URL debe apuntar a una base *_test", returncode=2)
    app = create_app()
    app.config["TESTING"] = True
    with app.app_context():
        db.drop_all()
        db.session.execute(text("DROP TABLE IF EXISTS schema_migrations"))
        db.session.commit()
        db.create_all()
        migrate()
        seed_catalogs()
        seed_csv()
        yield app
        db.session.remove()


@pytest.fixture()
def client(app):
    return app.test_client()


def _register(client) -> dict:
    email = f"test-{uuid.uuid4().hex[:10]}@diapce.test"
    res = client.post("/api/auth/register", json={"email": email, "password": "secreto123"})
    assert res.status_code == 201, res.get_json()
    return {"Authorization": f"Bearer {res.get_json()['access_token']}"}


@pytest.fixture()
def auth(client):
    """Cabeceras con el token de un usuario nuevo."""
    return _register(client)


@pytest.fixture()
def other_auth(client):
    """Cabeceras de un segundo usuario (para probar el aislamiento de datos)."""
    return _register(client)
