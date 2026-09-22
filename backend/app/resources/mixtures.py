"""Mezclas: /api/mixtures/<id>, /statistics, /materials."""
from flask.views import MethodView
from flask_jwt_extended import jwt_required
from flask_smorest import Blueprint, abort

from ..extensions import db
from ..mixtures_logic import mixture_statistics, preview_example_mixture, recalculate_percentages
from ..models import Material, Mixture, MixtureMaterial
from ..schemas import (
    MixtureMaterialInputSchema,
    MixturePreviewQuerySchema,
    MixtureSchema,
    MixtureStatsSchema,
)

blp = Blueprint("mixtures", __name__, url_prefix="/api/mixtures", description="Mezclas")


def _mixture(mixture_id: int) -> Mixture:
    mixture = db.session.get(Mixture, mixture_id)
    if mixture is None:
        abort(404, message="Mezcla no encontrada")
    return mixture


@blp.route("/preview")
class MixturePreview(MethodView):
    @jwt_required()
    @blp.arguments(MixturePreviewQuerySchema, location="query")
    @blp.response(200, MixtureSchema)
    def get(self, q):
        """Composición que se asignaría a un proyecto (sin guardar)."""
        return preview_example_mixture(q["work_type"], q["resistance_target"])


@blp.route("/<int:mixture_id>")
class MixtureItem(MethodView):
    @jwt_required()
    @blp.response(200, MixtureSchema)
    def get(self, mixture_id):
        """Mezcla con su composición de materiales (equivale a getMixtureWithMaterials)."""
        return _mixture(mixture_id)


@blp.route("/<int:mixture_id>/statistics")
class MixtureStats(MethodView):
    @jwt_required()
    @blp.response(200, MixtureStatsSchema)
    def get(self, mixture_id):
        """Totales de cantidad, costo y costo promedio por kg."""
        return mixture_statistics(_mixture(mixture_id))


@blp.route("/<int:mixture_id>/materials")
class MixtureMaterials(MethodView):
    @jwt_required()
    @blp.arguments(MixtureMaterialInputSchema)
    @blp.response(200, MixtureSchema)
    def post(self, data, mixture_id):
        """Agrega o actualiza la cantidad de un material y recalcula porcentajes."""
        mixture = _mixture(mixture_id)
        material = db.session.get(Material, data["material_id"])
        if material is None:
            abort(404, message="Material no encontrado")
        existing = next((mm for mm in mixture.materials if mm.material_id == material.id), None)
        if existing:
            existing.quantity = data["quantity"]
        else:
            mixture.materials.append(MixtureMaterial(material=material, quantity=data["quantity"]))
        recalculate_percentages(mixture)
        db.session.commit()
        return mixture


@blp.route("/<int:mixture_id>/materials/<int:material_id>")
class MixtureMaterialItem(MethodView):
    @jwt_required()
    @blp.response(200, MixtureSchema)
    def delete(self, mixture_id, material_id):
        """Quita un material de la mezcla y recalcula porcentajes."""
        mixture = _mixture(mixture_id)
        target = next((mm for mm in mixture.materials if mm.material_id == material_id), None)
        if target is None:
            abort(404, message="El material no está en la mezcla")
        mixture.materials.remove(target)
        recalculate_percentages(mixture)
        db.session.commit()
        return mixture
