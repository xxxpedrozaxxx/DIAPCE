"""Pruebas de la API REST de solo lectura y de proyectos (base diapce_test)."""


def test_health(client):
    res = client.get("/api/health")
    assert res.status_code == 200
    assert res.get_json()["status"] == "ok"


# ── Autenticación ───────────────────────────────────────────────────────
def test_registro_duplicado_y_login(client):
    body = {"email": "duplicado@diapce.test", "password": "secreto123"}
    assert client.post("/api/auth/register", json=body).status_code == 201
    assert client.post("/api/auth/register", json=body).status_code == 409
    assert client.post("/api/auth/login", json=body).status_code == 200
    malo = {**body, "password": "otra-clave"}
    assert client.post("/api/auth/login", json=malo).status_code == 401


def test_rutas_protegidas_exigen_token(client):
    for ruta in (
        "/api/projects",
        "/api/experiments/calibration",
        "/api/experiments/results",
        "/api/catalog/aditivos",
    ):
        assert client.get(ruta).status_code == 401, ruta


def test_token_de_usuario_eliminado_se_rechaza(app, client):
    from app.extensions import db
    from app.models import User

    res = client.post("/api/auth/register", json={"email": "borrado@diapce.test", "password": "secreto123"})
    headers = {"Authorization": f"Bearer {res.get_json()['access_token']}"}
    db.session.delete(db.session.get(User, res.get_json()["user"]["id"]))
    db.session.commit()
    assert client.get("/api/projects", headers=headers).status_code == 401


def test_contrasena_corta_se_rechaza(client):
    res = client.post("/api/auth/register", json={"email": "corta@diapce.test", "password": "123"})
    assert res.status_code == 422


# ── Catálogos y opciones en cascada ─────────────────────────────────────
def test_catalogos(client, auth):
    tipos = client.get("/api/catalog/tipos-estructura", headers=auth).get_json()
    assert {t["codigo"] for t in tipos} == {"Puentes", "Tuneles", "Muros"}
    aditivos = client.get("/api/catalog/aditivos", headers=auth).get_json()
    assert len(aditivos) == 7


def test_opciones_en_cascada(client, auth):
    temps = client.get("/api/experiments/options/temperatures", headers=auth).get_json()
    assert temps == [10, 25, 32]
    hum = client.get("/api/experiments/options/humidity?temperatura=25", headers=auth).get_json()
    assert 70 in hum


# ── Modelos matemáticos ─────────────────────────────────────────────────
def test_prediccion_combinacion_conocida(client, auth):
    res = client.get(
        "/api/experiments/predict?temperatura=25&humedad=70&relacion_ac=0.4&aditivo_id=7",
        headers=auth,
    )
    data = res.get_json()
    assert res.status_code == 200
    assert data["dias_28"] == 56.44
    assert data["num_muestras"] == 18
    assert data["curva"]["formula"].startswith("f(t) =")


def test_rangos_optimos(client, auth):
    data = client.get(
        "/api/experiments/optimal-ranges?resistencia_objetivo=45", headers=auth
    ).get_json()
    assert data["total_combinaciones"] == 91
    assert data["combinaciones_que_cumplen"] == 47
    assert {a["tipo_aditivo"] for a in data["aditivos"]} == {
        "Impermeabilizante", "Plastificante", "Sin aditivo",
    }
    assert data["mejores"][0]["promedio_28d"] >= data["mejores"][-1]["promedio_28d"]


def test_rangos_optimos_valida_objetivo(client, auth):
    res = client.get("/api/experiments/optimal-ranges?resistencia_objetivo=80", headers=auth)
    assert res.status_code == 422


def test_dispersion(client, auth):
    data = client.get(
        "/api/experiments/dispersion?variable=relacion_ac&edad_dias=28", headers=auth
    ).get_json()
    assert data["num_puntos"] == 624
    assert data["correlacion"] < 0  # más agua, menos resistencia
    assert [f["valor"] for f in data["tabla"]] == [0.4, 0.45, 0.5]
    assert sum(f["num_muestras"] for f in data["tabla"]) == 624


def test_dispersion_variable_invalida(client, auth):
    res = client.get("/api/experiments/dispersion?variable=color", headers=auth)
    assert res.status_code == 422


def test_calibracion_incluye_validacion_cruzada(client, auth):
    data = client.get("/api/experiments/calibration", headers=auth).get_json()
    assert data["num_ensayos"] == 1872
    val = data["validacion"]
    assert val["curva_log"]["n"] > 0
    assert 0 < val["curva_log"]["mae"] < 5
    assert {e["edad_dias"] for e in val["curva_log"]["por_edad"]} == {7, 14, 28}
    # El error sobre cilindros no vistos no puede ser menor que el de ajuste.
    assert val["curva_log"]["mae"] >= data["mae_global"]


# ── Proyectos ───────────────────────────────────────────────────────────
PROYECTO = {
    "project_name": "Puente de prueba",
    "work_type": "Puentes",
    "resistance_target": 42,
    "temperature": 25,
    "humidity": 70,
    "relacion_ac": 0.4,
    "aditivo_id": 7,
}


def test_proyecto_crud_y_aislamiento(client, auth, other_auth):
    res = client.post("/api/projects", json=PROYECTO, headers=auth)
    assert res.status_code == 201
    proyecto = res.get_json()
    assert proyecto["resistencia_predicha_28d"] == 56.44
    assert proyecto["mixture_id"] is not None

    # Otro usuario no ve ni puede modificar el proyecto.
    assert client.get("/api/projects", headers=other_auth).get_json() == []
    assert client.get(f"/api/projects/{proyecto['id']}", headers=other_auth).status_code == 404

    res = client.put(
        f"/api/projects/{proyecto['id']}", json={"project_name": "Renombrado"}, headers=auth
    )
    assert res.get_json()["project_name"] == "Renombrado"
    assert client.delete(f"/api/projects/{proyecto['id']}", headers=auth).status_code == 204
    assert client.get(f"/api/projects/{proyecto['id']}", headers=auth).status_code == 404


def test_proyecto_valida_resistencia_y_estructura(client, auth):
    assert client.post(
        "/api/projects", json={**PROYECTO, "resistance_target": 70}, headers=auth
    ).status_code == 422
    assert client.post(
        "/api/projects", json={**PROYECTO, "work_type": "Edificios"}, headers=auth
    ).status_code == 422
