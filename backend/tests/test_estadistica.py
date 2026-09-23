"""Pruebas de la dosificación ACI 211.1, la ANOVA, la regresión, la optimización y el reporte PDF."""
import pytest

from app.estadistica import resistencia_requerida
from app.mix_design import disenar


# ── Dosificación ACI 211.1 (sin base de datos) ─────────────────────────
def test_dosificacion_cumple_volumen_absoluto():
    d = disenar(0.45, "Puentes")
    s = d["supuestos"]
    assert d["agua"] == 205  # Tabla 6.3.3: asentamiento 75–100 mm, TMN 19 mm
    assert d["cemento"] == pytest.approx(205 / 0.45, abs=0.1)
    assert d["grava"] == pytest.approx(0.62 * 1600, abs=0.1)  # Tabla 6.3.6: MF 2,80
    volumen = (d["agua"] / 1000 + d["cemento"] / 3150 + d["grava"] / 2700 + d["arena"] / 2650
               + s["aire_atrapado_pct"] / 100)
    assert volumen == pytest.approx(1.0, abs=0.001)


def test_dosificacion_por_estructura_y_aditivo():
    muro = disenar(0.50, "Muros")
    tunel = disenar(0.50, "Tuneles")
    assert muro["agua"] < tunel["agua"]  # el túnel bombeado necesita más asentamiento
    con_aditivo = disenar(0.40, "Puentes", 0.6, "Plastificante")
    assert con_aditivo["aditivo"] == pytest.approx(con_aditivo["cemento"] * 0.006, abs=0.01)
    assert disenar(0.40, "Puentes")["aditivo"] == 0


def test_resistencia_requerida_aci_318():
    assert resistencia_requerida(30, 2.0) == pytest.approx(30 + 1.34 * 2)
    assert resistencia_requerida(30, 4.0) == pytest.approx(30 + 2.33 * 4 - 3.5)
    assert resistencia_requerida(40, 3.0) == pytest.approx(40 + 1.34 * 3)
    assert resistencia_requerida(50, 6.0) == pytest.approx(0.9 * 50 + 2.33 * 6)


# ── API ────────────────────────────────────────────────────────────────
def test_anova(client, auth):
    d = client.get("/api/experiments/anova?edad_dias=28", headers=auth).get_json()
    assert d["n"] == 624
    fuentes = {f["fuente"]: f for f in d["filas"]}
    for factor in ("Temperatura", "Humedad relativa", "Relación a/c", "Aditivo"):
        assert fuentes[factor]["p"] < 0.001
    assert fuentes["Temperatura"]["gl"] == 2
    assert fuentes["Aditivo"]["gl"] == 6
    assert d["residual"]["gl"] + sum(f["gl"] for f in d["filas"]) < d["total"]["gl"] + 1


def test_modelo_de_regresion(client, auth):
    d = client.get("/api/experiments/model", headers=auth).get_json()
    assert d["r2"] > 0.9
    assert len(d["coeficientes"]) == 9
    assert d["validacion"]["mae"] < 2.5
    t2 = next(c for c in d["coeficientes"] if c["termino"] == "T²")
    assert t2["valor"] < 0  # óptimo de temperatura intermedio


def test_optimizacion_factible(client, auth):
    body = {"resistencia_objetivo": 42, "temperatura": 25, "humedad": 70, "tipo_estructura": "Puentes"}
    d = client.post("/api/experiments/optimize", json=body, headers=auth).get_json()
    assert d["resistencia_requerida"] > 42
    mejor = d["alternativas"][0]
    assert mejor["factible"]
    assert mejor["prediccion"] >= d["resistencia_requerida"]
    assert 0.40 <= mejor["relacion_ac"] <= 0.50
    assert mejor["cemento"] == min(a["cemento"] for a in d["alternativas"] if a["factible"])
    assert d["advertencias"] == []


def test_optimizacion_advierte_extrapolacion_e_infactibilidad(client, auth):
    body = {"resistencia_objetivo": 55, "temperatura": 32, "humedad": 85, "tipo_estructura": "Tuneles"}
    d = client.post("/api/experiments/optimize", json=body, headers=auth).get_json()
    assert any("humedad" in a for a in d["advertencias"])
    assert not any(a["factible"] for a in d["alternativas"])


def test_optimizacion_valida_estructura(client, auth):
    body = {"resistencia_objetivo": 42, "temperatura": 25, "humedad": 70, "tipo_estructura": "Edificios"}
    assert client.post("/api/experiments/optimize", json=body, headers=auth).status_code == 422


def test_vista_previa_de_mezcla_aci(client, auth):
    d = client.get("/api/mixtures/preview?work_type=Puentes&relacion_ac=0.45&aditivo_id=6", headers=auth).get_json()
    cantidades = {m["name"]: m["quantity"] for m in d["materials"]}
    assert cantidades["Cemento Portland"] == pytest.approx(455.6, abs=0.1)
    assert cantidades["Agua"] == 205
    assert "Aditivo Plastificante" in cantidades
    assert "Fibra de Acero" not in cantidades
    assert "ACI 211.1" in d["description"]


def test_reporte_pdf(client, auth):
    proyecto = client.post("/api/projects", headers=auth, json={
        "project_name": "Muro de prueba", "work_type": "Muros", "resistance_target": 35,
        "temperature": 25, "humidity": 50, "relacion_ac": 0.45, "aditivo_id": 3,
    }).get_json()
    r = client.get(f"/api/projects/{proyecto['id']}/report", headers=auth)
    assert r.status_code == 200
    assert r.mimetype == "application/pdf"
    assert r.data.startswith(b"%PDF")
    client.delete(f"/api/projects/{proyecto['id']}", headers=auth)
