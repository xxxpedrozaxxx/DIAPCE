"""Pruebas del registro de ensayos, la importación CSV y la retroalimentación.

Estas pruebas modifican los datos: cada una borra lo que registra.
"""
import pytest

ENSAYO = {
    "temperatura": 28,
    "humedad": 80,
    "relacion_ac": 0.45,
    "edad_dias": 28,
    "resistencia_mpa": 44.2,
    "aditivo_id": 6,
    "tipo_estructura": "Puentes",
    "fecha_ensayo": "2026-09-20",
    "observaciones": "Cilindro 1",
}


def _historial(client, auth):
    return client.get("/api/experiments/calibration/history", headers=auth).get_json()


def _total(client, auth, **filtros):
    query = "&".join(f"{k}={v}" for k, v in filtros.items())
    return client.get(f"/api/experiments/results?{query}", headers=auth).get_json()["total"]


def test_registrar_ensayo_clasificado_y_recalibrar(client, auth):
    antes = len(_historial(client, auth))
    res = client.post("/api/experiments/results", json=ENSAYO, headers=auth)
    assert res.status_code == 201, res.get_json()
    ensayo = res.get_json()
    assert ensayo["origen"] == "registro"
    assert ensayo["tipo_estructura"] == "Puentes"
    assert ensayo["aditivo_codigo"] == "PP2"

    historial = _historial(client, auth)
    assert len(historial) == antes + 1
    assert historial[-1]["motivo"] == "registro"
    assert historial[-1]["num_ensayos"] == 1873

    # El ensayo nuevo aparece en el análisis filtrado por estructura.
    disp = client.get(
        "/api/experiments/dispersion?variable=temperatura&tipo_estructura=Puentes", headers=auth
    ).get_json()
    assert disp["num_puntos"] == 1
    assert disp["puntos"][0]["y"] == 44.2
    # Y aparece como opción nueva de temperatura en la cascada.
    temps = client.get("/api/experiments/options/temperatures", headers=auth).get_json()
    assert 28 in temps

    assert client.delete(f"/api/experiments/results/{ensayo['id']}", headers=auth).status_code == 204


@pytest.mark.parametrize(
    "cambio, campo",
    [
        ({"humedad": 150}, "humedad"),
        ({"resistencia_mpa": 0}, "resistencia_mpa"),
        ({"relacion_ac": 2}, "relacion_ac"),
        ({"tipo_estructura": "Edificios"}, "tipo_estructura"),
        ({"edad_dias": 0}, "edad_dias"),
    ],
)
def test_registro_valida_campos(client, auth, cambio, campo):
    res = client.post("/api/experiments/results", json={**ENSAYO, **cambio}, headers=auth)
    assert res.status_code == 422
    assert campo in res.get_json()["errors"]["json"]


def test_registro_rechaza_aditivo_inexistente(client, auth):
    res = client.post("/api/experiments/results", json={**ENSAYO, "aditivo_id": 99}, headers=auth)
    assert res.status_code == 422


def test_solo_el_autor_puede_eliminar(client, auth, other_auth):
    ensayo = client.post("/api/experiments/results", json=ENSAYO, headers=auth).get_json()
    url = f"/api/experiments/results/{ensayo['id']}"
    assert client.delete(url, headers=other_auth).status_code == 404
    assert client.delete(url, headers=auth).status_code == 204
    # Los ensayos históricos (semilla, sin autor) no se pueden borrar desde la API.
    assert client.delete("/api/experiments/results/1", headers=auth).status_code == 404


CSV_VALIDO = (
    "temperatura;humedad;relacion_ac;edad_dias;resistencia_mpa;aditivo;tipo_estructura;fecha_ensayo\n"
    "30;85;0,45;7;29,8;P2;Túneles;2026-09-01\n"
    "30;85;0,45;28;45,1;P2;tuneles;2026-09-22\n"
)


def test_importar_csv(client, auth):
    antes = _total(client, auth, tipo_estructura="Tuneles")
    res = client.post("/api/experiments/results/import", json={"csv": CSV_VALIDO}, headers=auth)
    assert res.status_code == 201, res.get_json()
    assert res.get_json() == {"insertados": 2, "errores": []}
    assert _total(client, auth, tipo_estructura="Tuneles") == antes + 2
    assert _historial(client, auth)[-1]["motivo"] == "importacion"

    items = client.get(
        "/api/experiments/results?tipo_estructura=Tuneles&origen=importacion", headers=auth
    ).get_json()["items"]
    assert {i["resistencia_mpa"] for i in items} >= {29.8, 45.1}
    for item in items:
        client.delete(f"/api/experiments/results/{item['id']}", headers=auth)


def test_importar_csv_con_errores_no_guarda_nada(client, auth):
    antes = _total(client, auth)
    csv = CSV_VALIDO + "30;150;0,45;28;45,1;P2;Muros\n30;85;0,45;28;45,1;X9;Muros\n"
    res = client.post("/api/experiments/results/import", json={"csv": csv}, headers=auth)
    assert res.status_code == 422
    body = res.get_json()
    assert body["insertados"] == 0
    assert [e["linea"] for e in body["errores"]] == [4, 5]
    assert _total(client, auth) == antes


def test_importar_csv_sin_columnas_obligatorias(client, auth):
    res = client.post(
        "/api/experiments/results/import", json={"csv": "temperatura,humedad\n25,70\n"}, headers=auth
    )
    assert res.status_code == 422
    assert "Faltan columnas" in res.get_json()["errores"][0]["mensaje"]


def test_recalibracion_manual(client, auth):
    res = client.post("/api/experiments/calibration/run", headers=auth)
    assert res.status_code == 201
    run = res.get_json()
    assert run["motivo"] == "manual"
    assert run["mae_validacion"] >= run["mae_ajuste"]
    assert _historial(client, auth)[-1]["id"] == run["id"]
