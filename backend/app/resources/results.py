"""Registro de ensayos de laboratorio: /api/experiments/results

- GET    /                → lista paginada (filtros: estructura, origen, edad)
- POST   /                → registra un ensayo (cilindro)
- POST   /import          → importa un lote CSV como texto (todo o nada)
- POST   /import-file     → igual, con archivo multipart (campo `file`)
- DELETE /<id>            → elimina un ensayo registrado por el mismo usuario

Cada alta recalibra el modelo y guarda la ejecución en el historial
(retroalimentación con los datos nuevos).
"""
from flask import request
from flask.views import MethodView
from flask_jwt_extended import get_jwt_identity, jwt_required
from flask_smorest import Blueprint, abort
from sqlalchemy import func, select

from ..analysis import SIN_CLASIFICAR, save_calibration
from ..extensions import db
from ..importer import parse_csv
from ..models import Aditivo, ResultadoConcreto, TipoEstructura
from ..schemas import (
    ImportCsvSchema,
    ImportResultSchema,
    ResultadoInputSchema,
    ResultadoPageSchema,
    ResultadoQuerySchema,
    ResultadoSchema,
)

blp = Blueprint(
    "results", __name__, url_prefix="/api/experiments/results",
    description="Registro de ensayos de laboratorio",
)


def _user_id() -> int:
    return int(get_jwt_identity())


def _tipos_estructura() -> dict[str, int]:
    return {t.codigo: t.id for t in db.session.scalars(select(TipoEstructura))}


def _build(data: dict, origen: str, tipos: dict[str, int]) -> ResultadoConcreto:
    data = dict(data)
    return ResultadoConcreto(
        tipo_estructura_id=tipos[data.pop("tipo_estructura")],
        registrado_por=_user_id(),
        origen=origen,
        **data,
    )


@blp.route("")
class ResultList(MethodView):
    @jwt_required()
    @blp.arguments(ResultadoQuerySchema, location="query")
    @blp.response(200, ResultadoPageSchema)
    def get(self, q):
        """Ensayos registrados, del más reciente al más antiguo."""
        stmt = select(ResultadoConcreto)
        if q.get("tipo_estructura") == SIN_CLASIFICAR:
            stmt = stmt.where(ResultadoConcreto.tipo_estructura_id.is_(None))
        elif q.get("tipo_estructura"):
            stmt = stmt.join(TipoEstructura).where(TipoEstructura.codigo == q["tipo_estructura"])
        if q.get("origen"):
            stmt = stmt.where(ResultadoConcreto.origen == q["origen"])
        if q.get("edad_dias"):
            stmt = stmt.where(ResultadoConcreto.edad_dias == q["edad_dias"])

        total = db.session.scalar(select(func.count()).select_from(stmt.subquery()))
        items = db.session.scalars(
            stmt.order_by(ResultadoConcreto.id.desc())
            .offset((q["page"] - 1) * q["per_page"])
            .limit(q["per_page"])
        ).all()
        return {"total": total, "page": q["page"], "per_page": q["per_page"], "items": items}

    @jwt_required()
    @blp.arguments(ResultadoInputSchema)
    @blp.response(201, ResultadoSchema)
    def post(self, data):
        """Registra el ensayo de un cilindro y recalibra el modelo."""
        if db.session.get(Aditivo, data["aditivo_id"]) is None:
            abort(422, message=f"aditivo_id inválido: {data['aditivo_id']}")
        resultado = _build(data, "registro", _tipos_estructura())
        db.session.add(resultado)
        db.session.commit()
        save_calibration("registro", _user_id())
        return resultado


@blp.route("/import")
class ResultImport(MethodView):
    @jwt_required()
    @blp.arguments(ImportCsvSchema)
    @blp.response(201, ImportResultSchema)
    @blp.alt_response(422, schema=ImportResultSchema, description="Líneas con errores; no se guarda nada")
    def post(self, data):
        """Importa ensayos desde texto CSV. Si una línea falla, no se guarda ninguna."""
        return _import(data["csv"])


def _import(text: str):
    rows, errors = parse_csv(text)
    if errors:
        return {"insertados": 0, "errores": errors}, 422
    tipos = _tipos_estructura()
    db.session.add_all(_build(r, "importacion", tipos) for r in rows)
    db.session.commit()
    save_calibration("importacion", _user_id())
    return {"insertados": len(rows), "errores": []}


@blp.route("/<int:resultado_id>")
class ResultItem(MethodView):
    @jwt_required()
    @blp.response(204)
    def delete(self, resultado_id):
        """Elimina un ensayo mal digitado. Solo el usuario que lo registró puede hacerlo."""
        resultado = db.session.get(ResultadoConcreto, resultado_id)
        if resultado is None or resultado.registrado_por != _user_id():
            abort(404, message="Ensayo no encontrado")
        db.session.delete(resultado)
        db.session.commit()
        save_calibration("eliminacion", _user_id())


@blp.route("/import-file")
class ResultImportFile(MethodView):
    @jwt_required()
    @blp.response(201, ImportResultSchema)
    @blp.alt_response(422, schema=ImportResultSchema, description="Líneas con errores; no se guarda nada")
    def post(self):
        """Importa ensayos desde un archivo CSV (multipart/form-data, campo `file`)."""
        upload = request.files.get("file")
        if upload is None:
            abort(422, message="Adjunta el archivo CSV en el campo 'file'")
        return _import(upload.read().decode("utf-8-sig"))
