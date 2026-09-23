"""Pruebas unitarias de las funciones numéricas de app/analysis.py (sin base de datos)."""
import math
from types import SimpleNamespace

import pytest

from app.analysis import (
    CONTROL_LABEL,
    _error_metrics,
    cross_validation,
    eval_curve,
    fit_log_curve,
    pearson,
    porcentaje_valor,
    tipo_aditivo_label,
)


def test_fit_log_curve_recupera_coeficientes_exactos():
    puntos = [(t, 5 + 10 * math.log(t)) for t in (7, 14, 28)]
    curva = fit_log_curve(puntos)
    assert curva["a"] == pytest.approx(5, abs=1e-3)
    assert curva["b"] == pytest.approx(10, abs=1e-3)
    assert curva["r2"] == pytest.approx(1.0)
    assert eval_curve(curva, 28) == pytest.approx(5 + 10 * math.log(28), abs=0.01)


def test_fit_log_curve_necesita_dos_edades_distintas():
    assert fit_log_curve([(28, 40.0)]) is None
    assert fit_log_curve([(28, 40.0), (28, 42.0)]) is None
    assert fit_log_curve([]) is None


def test_porcentaje_valor_convierte_texto_del_catalogo():
    assert porcentaje_valor("0.4%") == 0.4
    assert porcentaje_valor("3%") == 3.0
    assert porcentaje_valor("0,6 %") == 0.6
    assert porcentaje_valor("") == 0.0
    assert porcentaje_valor(None) == 0.0


def test_control_se_reporta_como_sin_aditivo():
    assert tipo_aditivo_label("Impermeabilizante", 0.0) == CONTROL_LABEL
    assert tipo_aditivo_label("Plastificante", 0.4) == "Plastificante"


def test_pearson():
    assert pearson([1, 2, 3], [2, 4, 6]) == pytest.approx(1.0)
    assert pearson([1, 2, 3], [6, 4, 2]) == pytest.approx(-1.0)
    assert pearson([1, 1, 1], [1, 2, 3]) is None
    assert pearson([1], [1]) is None


def test_error_metrics():
    m = _error_metrics([(10.0, 9.0), (20.0, 22.0)])
    assert m["n"] == 2
    assert m["mae"] == pytest.approx(1.5)
    assert m["rmse"] == pytest.approx(math.sqrt((1 + 4) / 2), abs=1e-3)
    assert m["mape"] == pytest.approx((10 + 10) / 2)
    assert _error_metrics([])["mae"] is None


def _cilindro(edad, resistencia):
    return SimpleNamespace(edad_dias=edad, resistencia_mpa=resistencia)


def test_validacion_cruzada_sin_ruido_tiene_error_cero():
    # Todos los cilindros caen exactamente sobre la curva: dejar uno fuera no cambia nada.
    rs = [_cilindro(t, 4 + 15 * math.log(t)) for t in (7, 14, 28) for _ in range(3)]
    val = cross_validation({("combo",): rs})
    assert val["curva_log"]["n"] == 9
    assert val["curva_log"]["mae"] == pytest.approx(0, abs=1e-6)
    assert val["promedio_edad"]["mae"] == pytest.approx(0, abs=1e-6)
    assert [e["edad_dias"] for e in val["curva_log"]["por_edad"]] == [7, 14, 28]


def test_validacion_cruzada_no_usa_el_cilindro_evaluado():
    # Con dos cilindros por edad, el promedio "sin él" es el otro cilindro.
    rs = [_cilindro(28, 40.0), _cilindro(28, 44.0), _cilindro(7, 30.0), _cilindro(7, 30.0)]
    val = cross_validation({("combo",): rs})
    edad28 = next(e for e in val["promedio_edad"]["por_edad"] if e["edad_dias"] == 28)
    assert edad28["mae"] == pytest.approx(4.0)
