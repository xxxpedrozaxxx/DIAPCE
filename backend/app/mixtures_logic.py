"""Composición de la mezcla de un proyecto.

La composición de 1 m³ se calcula con el método ACI 211.1 (`mix_design.py`) a
partir de la relación agua/cemento y el aditivo elegidos en el proyecto —las
mismas condiciones de los ensayos que sustentan la predicción— y del tipo de
estructura. Las densidades de cemento, arena y grava se toman del catálogo
de materiales cuando están disponibles.
"""
from __future__ import annotations

from sqlalchemy import select

from .analysis import porcentaje_valor
from .extensions import db
from .mix_design import Materiales, disenar
from .models import Aditivo, Material, Mixture, MixtureMaterial

NOMBRES = {
    "cemento": "Cemento Portland",
    "agua": "Agua",
    "arena": "Arena",
    "grava": "Grava",
    "Plastificante": "Aditivo Plastificante",
    "Impermeabilizante": "Aditivo Impermeabilizante",
}
ESTRUCTURAS = {"Puentes": "puente", "Tuneles": "túnel", "Muros": "muro de contención"}


def _catalogo() -> dict[str, Material]:
    return {m.name: m for m in db.session.scalars(select(Material).where(Material.name.in_(NOMBRES.values())))}


def _materiales(catalogo: dict[str, Material]) -> Materiales:
    m = Materiales()
    for campo, nombre in (("densidad_cemento", "Cemento Portland"), ("densidad_arena", "Arena"),
                          ("densidad_grava", "Grava")):
        if catalogo.get(nombre) and catalogo[nombre].density:
            setattr(m, campo, catalogo[nombre].density)
    return m


def _aditivo(aditivo_id: int | None) -> tuple[float, str | None, str | None]:
    """(dosis %, tipo, código) del aditivo; el control P0 no lleva aditivo."""
    aditivo = db.session.get(Aditivo, aditivo_id) if aditivo_id else None
    if aditivo is None:
        return 0.0, None, None
    dosis = porcentaje_valor(aditivo.porcentaje_aplicado)
    return dosis, (aditivo.tipo_aditivo.nombre if dosis > 0 else None), aditivo.codigo


def proporciones(relacion_ac: float, tipo_estructura: str | None, aditivo_id: int | None) -> dict:
    """Diseño ACI 211.1 con los materiales del catálogo: {diseno, filas, nombre, descripcion}."""
    catalogo = _catalogo()
    dosis, tipo, codigo = _aditivo(aditivo_id)
    diseno = disenar(relacion_ac, tipo_estructura, dosis, tipo, _materiales(catalogo))
    filas = []
    for clave in ("cemento", "agua", "arena", "grava"):
        filas.append((catalogo.get(NOMBRES[clave]), diseno[clave]))
    if diseno["aditivo"] and tipo:
        material = catalogo.get(NOMBRES[tipo])
        cantidad = diseno["aditivo"]
        if material is not None and material.unit == "L" and material.density:
            cantidad = round(cantidad / material.density, 2)  # kg → L
        filas.append((material, cantidad))
    sup = diseno["supuestos"]
    aditivo_txt = f"{codigo} ({tipo.lower()} {dosis:g} %)" if tipo else "sin aditivo"
    return {
        "diseno": diseno,
        "filas": [(m, q) for m, q in filas if m is not None],
        "nombre": f"Dosificación ACI 211.1 · a/c {relacion_ac:.2f}",
        "descripcion": (
            f"Mezcla para {ESTRUCTURAS.get(tipo_estructura or '', 'estructura')} por volumen absoluto "
            f"(ACI 211.1): a/c {relacion_ac:.2f}, {aditivo_txt}, asentamiento {sup['asentamiento']}, "
            f"TMN {sup['tamano_maximo_mm']:g} mm, módulo de finura {sup['modulo_finura_arena']:.2f}, "
            f"aire atrapado {sup['aire_atrapado_pct']:g} %."
        ),
    }


def recalculate_percentages(mixture: Mixture) -> None:
    total = sum(mm.quantity for mm in mixture.materials)
    for mm in mixture.materials:
        mm.percentage = round(mm.quantity / total * 100, 2) if total > 0 else None


def preview_example_mixture(work_type: str | None, relacion_ac: float, aditivo_id: int | None) -> dict:
    """Composición que se generaría para un proyecto, sin persistir nada."""
    p = proporciones(relacion_ac, work_type, aditivo_id)
    total = sum(q for _, q in p["filas"])
    materials = [
        {"material_id": m.id, "material": m, "quantity": q,
         "percentage": round(q / total * 100, 2) if total else None}
        for m, q in p["filas"]
    ]
    return {
        "id": None, "name": p["nombre"], "description": p["descripcion"],
        "total_volume": 1.0, "project_id": None, "created_at": None, "materials": materials,
    }


def create_example_mixture(
    project_name: str, work_type: str | None, relacion_ac: float, aditivo_id: int | None
) -> Mixture:
    """Crea (sin commit) la mezcla de 1 m³ del proyecto."""
    p = proporciones(relacion_ac, work_type, aditivo_id)
    mixture = Mixture(name=f"{p['nombre']} - {project_name}", description=p["descripcion"], total_volume=1.0)
    for material, cantidad in p["filas"]:
        mixture.materials.append(MixtureMaterial(material=material, quantity=cantidad))
    recalculate_percentages(mixture)
    db.session.add(mixture)
    return mixture


def mixture_cost(filas) -> float | None:
    """Costo de referencia con los precios del catálogo (None si falta algún precio)."""
    if any(m.cost_per_unit is None for m, _ in filas):
        return None
    return round(sum(m.cost_per_unit * q for m, q in filas), 2)


def mixture_statistics(mixture: Mixture) -> dict:
    total_qty = sum(mm.quantity for mm in mixture.materials)
    total_cost = sum((mm.material.cost_per_unit or 0.0) * mm.quantity for mm in mixture.materials)
    return {
        "totalQuantity": round(total_qty, 3),
        "totalCost": round(total_cost, 2),
        "materialCount": float(len(mixture.materials)),
        "averageCostPerKg": round(total_cost / total_qty, 4) if total_qty > 0 else 0.0,
    }
