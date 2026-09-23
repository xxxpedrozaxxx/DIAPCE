"""Reporte PDF de un proyecto (botón «Descargar» de la aplicación).

Incluye los datos del proyecto, las condiciones, la predicción de resistencia
con la curva ajustada sobre los ensayos, la gráfica de desarrollo de
resistencia y la dosificación ACI 211.1 de la mezcla. Se genera con
ReportLab, sin archivos temporales.
"""
from __future__ import annotations

import io
import math
from datetime import datetime

from reportlab.graphics.charts.lineplots import LinePlot
from reportlab.graphics.shapes import Circle, Drawing, Line, String
from reportlab.graphics.widgets.markers import makeMarker
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import KeepTogether, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from .analysis import predict_strength
from .extensions import db
from .models import Aditivo, Project

AZUL = colors.HexColor("#2E4FD8")
AMBAR = colors.HexColor("#F5A524")
GRIS = colors.HexColor("#6B7280")
ESTRUCTURAS = {"Puentes": "Puentes", "Tuneles": "Túneles", "Muros": "Muros de contención"}


def _num(v, d=1):
    return "—" if v is None else f"{v:.{d}f}".replace(".", ",")


def _tabla(filas, anchos, encabezado=True):
    t = Table(filas, colWidths=anchos)
    estilo = [
        ("FONT", (0, 0), (-1, -1), "Helvetica", 9),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LINEABOVE", (0, 0), (-1, 0), 0.8, colors.black),
        ("LINEBELOW", (0, -1), (-1, -1), 0.8, colors.black),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
    ]
    if encabezado:
        estilo += [("FONT", (0, 0), (-1, 0), "Helvetica-Bold", 9),
                   ("LINEBELOW", (0, 0), (-1, 0), 0.5, colors.black)]
    t.setStyle(TableStyle(estilo))
    return t


def _grafica(pred: dict, objetivo: float) -> Drawing:
    d = Drawing(16 * cm, 7 * cm)
    lp = LinePlot()
    lp.x, lp.y, lp.width, lp.height = 1.4 * cm, 1.0 * cm, 14 * cm, 5.4 * cm
    curva = pred.get("curva")
    series = []
    if curva:
        series.append([(t, curva["a"] + curva["b"] * math.log(t)) for t in range(3, 29)])
    medidos = [(s["edad_dias"], s["promedio"]) for s in pred["por_edad"]]
    # ReportLab exige al menos dos puntos por serie.
    series.append(medidos * 2 if len(medidos) == 1 else medidos or [(0, 0), (0, 0)])
    series.append([(0, objetivo), (28, objetivo)])
    lp.data = series
    maximo = max([y for s in series for _, y in s] + [objetivo]) * 1.15
    lp.xValueAxis.valueMin, lp.xValueAxis.valueMax, lp.xValueAxis.valueSteps = 0, 28, [0, 7, 14, 21, 28]
    lp.yValueAxis.valueMin, lp.yValueAxis.valueMax = 0, math.ceil(maximo / 10) * 10
    lp.xValueAxis.labels.fontSize = lp.yValueAxis.labels.fontSize = 8
    lp.xValueAxis.labels.fontName = lp.yValueAxis.labels.fontName = "Helvetica"
    i = 0
    if curva:
        lp.lines[0].strokeColor, lp.lines[0].strokeWidth = AZUL, 2
        i = 1
    lp.lines[i].strokeColor = colors.transparent
    lp.lines[i].symbol = makeMarker("FilledCircle", size=6, fillColor=AMBAR, strokeColor=AMBAR)
    lp.lines[i + 1].strokeColor, lp.lines[i + 1].strokeDashArray = colors.red, [4, 3]
    d.add(lp)
    d.add(String(8 * cm, 0.1 * cm, "Edad (días)", fontSize=8, fontName="Helvetica", textAnchor="middle"))
    d.add(String(0.2 * cm, 6.6 * cm, "MPa", fontSize=8, fontName="Helvetica"))
    y0 = 6.7 * cm
    for x, color, txt, linea in ((4 * cm, AZUL, "Curva ajustada", True), (7.5 * cm, AMBAR, "Promedio de ensayos", False),
                                 (11.5 * cm, colors.red, "Resistencia objetivo", True)):
        if linea:
            d.add(Line(x, y0 + 3, x + 12, y0 + 3, strokeColor=color, strokeWidth=2))
        else:
            d.add(Circle(x + 6, y0 + 3, 3, fillColor=color, strokeColor=color))
        d.add(String(x + 16, y0, txt, fontSize=8, fontName="Helvetica"))
    return d


def reporte_proyecto(project: Project) -> bytes:
    pred = predict_strength(project.temperature, project.humidity, project.relacion_ac, project.aditivo_id or 1)
    base = getSampleStyleSheet()
    titulo = ParagraphStyle("t", parent=base["Title"], fontSize=16, textColor=AZUL, spaceAfter=4)
    h2 = ParagraphStyle("h2", parent=base["Heading2"], fontSize=12, spaceBefore=10, spaceAfter=4)
    normal = ParagraphStyle("n", parent=base["Normal"], fontSize=9, leading=12)
    pie = ParagraphStyle("p", parent=normal, textColor=GRIS, fontSize=8)

    aditivo_txt = "Sin aditivo (control)"
    if project.aditivo_id:
        aditivo = db.session.get(Aditivo, project.aditivo_id)
        if aditivo is not None:
            aditivo_txt = f"{aditivo.codigo} · {aditivo.tipo_aditivo.nombre} {aditivo.porcentaje_aplicado}"
            if aditivo.porcentaje_aplicado == "0%":
                aditivo_txt = f"{aditivo.codigo} · sin aditivo (control)"

    el = [
        Paragraph("DIAPCE · Reporte de proyecto", titulo),
        Paragraph(f"<b>{project.project_name}</b>", ParagraphStyle("pn", parent=normal, fontSize=12, leading=15)),
        Paragraph(f"Generado el {datetime.now().strftime('%d/%m/%Y %H:%M')}", pie),
        Spacer(1, 6),
        Paragraph("Datos del proyecto", h2),
        _tabla([
            ["Tipo de estructura", ESTRUCTURAS.get(project.tipo_estructura.codigo, project.tipo_estructura.codigo)],
            ["Resistencia objetivo", f"{_num(project.resistance_target)} MPa a 28 días"],
            ["Creador", project.creator_name or "—"],
            ["Fecha", (project.selected_date or "")[:10] or "—"],
        ], [5 * cm, 11 * cm], encabezado=False),
        Paragraph("Condiciones de la mezcla", h2),
        _tabla([
            ["Temperatura de curado", f"{project.temperature} °C"],
            ["Humedad relativa", f"{project.humidity} %"],
            ["Relación agua/cemento", _num(project.relacion_ac, 2)],
            ["Aditivo", aditivo_txt],
        ], [5 * cm, 11 * cm], encabezado=False),
        Paragraph("Predicción de resistencia a la compresión", h2),
        _tabla(
            [["Edad", "Promedio (MPa)", "Desv. estándar", "Mínimo", "Máximo", "Ensayos"]]
            + [[f"{s['edad_dias']} días", _num(s["promedio"], 2), _num(s["desviacion"], 2), _num(s["minimo"], 2),
                _num(s["maximo"], 2), str(s["num_muestras"])] for s in pred["por_edad"]],
            [2.4 * cm, 2.8 * cm, 2.8 * cm, 2.6 * cm, 2.6 * cm, 2.4 * cm],
        ),
        Spacer(1, 4),
        Paragraph(
            (f"Curva ajustada por mínimos cuadrados: <b>{pred['curva']['formula'].replace('.', ',')}</b> "
             f"(R² = {_num(pred['curva']['r2'], 3)}), con {pred['num_muestras']} ensayos de laboratorio de "
             "estas condiciones.") if pred.get("curva") else "Sin ensayos suficientes para ajustar la curva.",
            normal),
    ]
    if pred["por_edad"]:
        el.append(_grafica(pred, project.resistance_target))

    mezcla = project.mixture
    if mezcla is not None and mezcla.materials:
        el.append(KeepTogether([
            Paragraph("Dosificación por m³ de concreto", h2),
            Paragraph(mezcla.description or "", normal),
            Spacer(1, 4),
            _tabla([["Material", "Cantidad", "Unidad", "Proporción"]]
                   + [[mm.material.name, _num(mm.quantity, 1), mm.material.unit, f"{_num(mm.percentage, 1)} %"]
                      for mm in mezcla.materials],
                   [7 * cm, 3 * cm, 2.5 * cm, 3.5 * cm]),
        ]))
    el += [
        Spacer(1, 12),
        Paragraph(
            "La predicción resume los ensayos del laboratorio para las condiciones indicadas y no reemplaza el "
            "diseño estructural ni la verificación de la NSR-10. La dosificación sigue el método de volumen "
            "absoluto del ACI 211.1 con propiedades supuestas de los agregados; debe ajustarse con los materiales "
            "reales y validarse con mezclas de prueba.", pie),
    ]

    buffer = io.BytesIO()
    SimpleDocTemplate(buffer, pagesize=letter, leftMargin=2.2 * cm, rightMargin=2.2 * cm, topMargin=1.8 * cm,
                      bottomMargin=1.8 * cm, title=f"DIAPCE - {project.project_name}", author="DIAPCE").build(el)
    return buffer.getvalue()
