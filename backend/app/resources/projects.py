"""CRUD de proyectos: /api/projects (siempre filtrado por el usuario del token)."""
from flask.views import MethodView
from flask_jwt_extended import get_jwt_identity, jwt_required
from flask_smorest import Blueprint, abort
from sqlalchemy import select

from ..analysis import predict_strength
from ..extensions import db
from ..mixtures_logic import create_example_mixture
from ..models import Project, TipoEstructura
from ..schemas import ProjectPartialSchema, ProjectSchema

blp = Blueprint("projects", __name__, url_prefix="/api/projects", description="Proyectos")


def _current_user_id() -> int:
    return int(get_jwt_identity())


def _tipo_estructura(codigo: str) -> TipoEstructura:
    tipo = db.session.scalar(select(TipoEstructura).where(TipoEstructura.codigo == codigo))
    if tipo is None:
        abort(422, message=f"work_type inválido: {codigo}. Usa Puentes, Tuneles o Muros.")
    return tipo


def _own_project(project_id: int) -> Project:
    project = db.session.get(Project, project_id)
    if project is None or project.user_id != _current_user_id():
        abort(404, message="Proyecto no encontrado")
    return project


def _serialize(project: Project) -> dict:
    """Aplana tipo_estructura → work_type para el cliente."""
    data = {c.name: getattr(project, c.name) for c in Project.__table__.columns}
    data["work_type"] = project.tipo_estructura.codigo
    return data


@blp.route("")
class ProjectList(MethodView):
    @jwt_required()
    @blp.response(200, ProjectSchema(many=True))
    def get(self):
        """Lista los proyectos del usuario autenticado."""
        rows = db.session.scalars(
            select(Project).where(Project.user_id == _current_user_id()).order_by(Project.id)
        ).all()
        return [_serialize(p) for p in rows]

    @jwt_required()
    @blp.arguments(ProjectSchema)
    @blp.response(201, ProjectSchema)
    def post(self, data):
        """Crea un proyecto.

        Equivale a `ProjectService.saveCompleteProject` del cliente:
        - si no trae predicciones, las calcula en el servidor;
        - si no trae mixture_id, genera la mezcla de ejemplo según tipo de
          estructura y resistencia objetivo, y la enlaza en ambos sentidos.
        """
        work_type = data.pop("work_type")
        tipo = _tipo_estructura(work_type)

        if data.get("resistencia_predicha_28d") is None:
            pred = predict_strength(
                data["temperature"], data["humidity"], data["relacion_ac"], data.get("aditivo_id") or 1
            )
            data["resistencia_predicha_7d"] = pred["dias_7"]
            data["resistencia_predicha_14d"] = pred["dias_14"]
            data["resistencia_predicha_28d"] = pred["dias_28"]

        project = Project(user_id=_current_user_id(), tipo_estructura=tipo, **data)
        if project.mixture_id is None:
            project.mixture = create_example_mixture(
                project.project_name, work_type, project.resistance_target
            )
        db.session.add(project)
        db.session.flush()
        if project.mixture is not None:
            project.mixture.project_id = project.id
        db.session.commit()
        return _serialize(project)


@blp.route("/<int:project_id>")
class ProjectItem(MethodView):
    @jwt_required()
    @blp.response(200, ProjectSchema)
    def get(self, project_id):
        return _serialize(_own_project(project_id))

    @jwt_required()
    @blp.arguments(ProjectPartialSchema)
    @blp.response(200, ProjectSchema)
    def put(self, data, project_id):
        """Actualización parcial."""
        project = _own_project(project_id)
        if "work_type" in data:
            project.tipo_estructura = _tipo_estructura(data.pop("work_type"))
        for key, value in data.items():
            setattr(project, key, value)
        db.session.commit()
        return _serialize(project)

    @jwt_required()
    @blp.response(204)
    def delete(self, project_id):
        project = _own_project(project_id)
        if project.mixture is not None:
            db.session.delete(project.mixture)
        db.session.delete(project)
        db.session.commit()
