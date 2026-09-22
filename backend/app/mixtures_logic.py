"""Lógica de dosificación de mezclas de ejemplo.

Port de `createRandomExampleMixture` de lib/core/database_helper.dart con un
cambio: la plantilla ya no se elige al azar, sino según el tipo de estructura
y la resistencia objetivo del proyecto (clasificación del objetivo 1).
"""
from __future__ import annotations

from sqlalchemy import select

from .extensions import db
from .models import Material, Mixture, MixtureMaterial

# Cantidades en kg (o L para agua/aditivos) por 1 m³.
TEMPLATES: dict[str, dict] = {
    "estandar": {
        "name": "Concreto Estándar",
        "description": "Mezcla estándar para construcción general",
        "materials": {"Cemento Portland": 350.0, "Agua": 175.0, "Arena": 700.0, "Grava": 1100.0, "Aditivo Plastificante": 1.2},
    },
    "alta_resistencia": {
        "name": "Concreto de Alta Resistencia",
        "description": "Mezcla para estructuras que requieren alta resistencia",
        "materials": {"Cemento Portland": 450.0, "Agua": 160.0, "Arena": 650.0, "Grava": 1050.0, "Aditivo Plastificante": 2.0, "Fibra de Acero": 25.0},
    },
    "fluido": {
        "name": "Concreto Fluido",
        "description": "Mezcla de alta trabajabilidad para elementos complejos",
        "materials": {"Cemento Portland": 380.0, "Agua": 190.0, "Arena": 750.0, "Grava": 1000.0, "Aditivo Plastificante": 3.5},
    },
    "ligero": {
        "name": "Concreto Ligero",
        "description": "Mezcla con agregados ligeros para reducir peso",
        "materials": {"Cemento Portland": 320.0, "Agua": 180.0, "Arena": 600.0, "Grava": 800.0, "Aditivo Plastificante": 1.5},
    },
    "pavimentos": {
        "name": "Concreto para Pavimentos",
        "description": "Mezcla especializada para pavimentación",
        "materials": {"Cemento Portland": 400.0, "Agua": 165.0, "Arena": 680.0, "Grava": 1150.0, "Aditivo Plastificante": 1.8, "Fibra de Acero": 15.0},
    },
    "premezclado": {
        "name": "Concreto Premezclado",
        "description": "Mezcla estándar para concreto premezclado",
        "materials": {"Cemento Portland": 330.0, "Agua": 185.0, "Arena": 720.0, "Grava": 1080.0, "Aditivo Plastificante": 1.0},
    },
    "autocompactante": {
        "name": "Concreto Autocompactante",
        "description": "Mezcla que se compacta por gravedad",
        "materials": {"Cemento Portland": 420.0, "Agua": 170.0, "Arena": 800.0, "Grava": 950.0, "Aditivo Plastificante": 4.2},
    },
    "fibras": {
        "name": "Concreto Reforzado con Fibras",
        "description": "Mezcla con alto contenido de fibras de refuerzo",
        "materials": {"Cemento Portland": 380.0, "Agua": 175.0, "Arena": 690.0, "Grava": 1020.0, "Aditivo Plastificante": 2.5, "Fibra de Acero": 40.0},
    },
}

# (tipo de estructura) → (plantilla para resistencia normal, plantilla para ≥ 40 MPa)
BY_STRUCTURE: dict[str, tuple[str, str]] = {
    "Puentes": ("fibras", "alta_resistencia"),
    "Tuneles": ("fluido", "autocompactante"),
    "Muros": ("estandar", "pavimentos"),
}
HIGH_STRENGTH_MPA = 40.0


def select_template(work_type: str | None, resistance_target: float) -> dict:
    normal, high = BY_STRUCTURE.get(work_type or "", ("premezclado", "alta_resistencia"))
    return TEMPLATES[high if resistance_target >= HIGH_STRENGTH_MPA else normal]


def recalculate_percentages(mixture: Mixture) -> None:
    total = sum(mm.quantity for mm in mixture.materials)
    for mm in mixture.materials:
        mm.percentage = round(mm.quantity / total * 100, 2) if total > 0 else None


def preview_example_mixture(work_type: str | None, resistance_target: float) -> dict:
    """Composición que se generaría para un proyecto, sin persistir nada."""
    template = select_template(work_type, resistance_target)
    by_name = {
        m.name: m
        for m in db.session.scalars(select(Material).where(Material.name.in_(template["materials"]))).all()
    }
    total = sum(q for n, q in template["materials"].items() if n in by_name)
    materials = [
        {
            "material_id": m.id, "material": m, "quantity": qty,
            "percentage": round(qty / total * 100, 2) if total else None,
        }
        for name, qty in template["materials"].items()
        if (m := by_name.get(name)) is not None
    ]
    return {
        "id": None, "name": template["name"], "description": template["description"],
        "total_volume": 1.0, "project_id": None, "created_at": None, "materials": materials,
    }


def create_example_mixture(project_name: str, work_type: str | None, resistance_target: float) -> Mixture:
    """Crea (sin commit) una mezcla de 1 m³ con la plantilla adecuada."""
    template = select_template(work_type, resistance_target)
    mixture = Mixture(
        name=f"{template['name']} - {project_name}",
        description=template["description"],
        total_volume=1.0,
    )
    by_name = {
        m.name: m
        for m in db.session.scalars(select(Material).where(Material.name.in_(template["materials"]))).all()
    }
    for name, qty in template["materials"].items():
        material = by_name.get(name)
        if material is not None:
            mixture.materials.append(MixtureMaterial(material=material, quantity=qty))
    recalculate_percentages(mixture)
    db.session.add(mixture)
    return mixture


def mixture_statistics(mixture: Mixture) -> dict:
    total_qty = sum(mm.quantity for mm in mixture.materials)
    total_cost = sum((mm.material.cost_per_unit or 0.0) * mm.quantity for mm in mixture.materials)
    return {
        "totalQuantity": round(total_qty, 3),
        "totalCost": round(total_cost, 2),
        "materialCount": float(len(mixture.materials)),
        "averageCostPerKg": round(total_cost / total_qty, 4) if total_qty > 0 else 0.0,
    }
