"""Modelos SQLAlchemy — esquema DIAPCE v5 (PostgreSQL).

Equivale a las 9 tablas de docs/base_de_datos.md (v4) más `tipos_estructura`,
con estos cambios respecto a SQLite:
- AUTOINCREMENT → SERIAL (Integer + primary_key).
- projects.resistance_target INTEGER → REAL (Float).
- projects.work_type TEXT libre → FK tipo_estructura_id.
- users.password guarda hash bcrypt, nunca texto plano.
- Todas las FK con ON DELETE explícito.
"""
from datetime import datetime, timezone

from sqlalchemy import (
    CheckConstraint,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .extensions import db


def _now():
    return datetime.now(timezone.utc)


class User(db.Model):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(default=_now, nullable=False)

    projects: Mapped[list["Project"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )


class TipoEstructura(db.Model):
    """Clasificación por tipo de estructura (objetivo 1): puentes, túneles, muros."""

    __tablename__ = "tipos_estructura"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    codigo: Mapped[str] = mapped_column(String(32), unique=True, nullable=False)
    nombre: Mapped[str] = mapped_column(String(64), nullable=False)


class Material(db.Model):
    __tablename__ = "materials"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(128), unique=True, nullable=False)
    unit: Mapped[str] = mapped_column(String(16), nullable=False)
    density: Mapped[float | None] = mapped_column(Float)
    cost_per_unit: Mapped[float | None] = mapped_column(Float)
    description: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(default=_now, nullable=False)


class TipoAditivo(db.Model):
    __tablename__ = "tipos_aditivo"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    nombre: Mapped[str] = mapped_column(String(64), unique=True, nullable=False)


class Producto(db.Model):
    __tablename__ = "productos"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    nombre_producto: Mapped[str] = mapped_column(String(128), unique=True, nullable=False)
    marca: Mapped[str | None] = mapped_column(String(64))


class Aditivo(db.Model):
    __tablename__ = "aditivos"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    codigo: Mapped[str] = mapped_column(String(16), unique=True, nullable=False)
    porcentaje_aplicado: Mapped[str] = mapped_column(String(16), nullable=False)
    tipo_aditivo_id: Mapped[int] = mapped_column(
        ForeignKey("tipos_aditivo.id", ondelete="CASCADE"), nullable=False
    )
    producto_id: Mapped[int] = mapped_column(
        ForeignKey("productos.id", ondelete="CASCADE"), nullable=False
    )

    tipo_aditivo: Mapped[TipoAditivo] = relationship()
    producto: Mapped[Producto] = relationship()


class ResultadoConcreto(db.Model):
    """Ensayo experimental de laboratorio (importado del CSV)."""

    __tablename__ = "resultados_concreto"
    __table_args__ = (
        Index(
            "idx_busqueda_resistencia",
            "temperatura", "humedad", "relacion_ac", "aditivo_id", "edad_dias",
        ),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    temperatura: Mapped[int] = mapped_column(Integer, nullable=False)
    humedad: Mapped[int] = mapped_column(Integer, nullable=False)
    relacion_ac: Mapped[float] = mapped_column(Float, nullable=False)
    edad_dias: Mapped[int] = mapped_column(Integer, nullable=False)
    resistencia_mpa: Mapped[float] = mapped_column(Float, nullable=False)
    aditivo_id: Mapped[int] = mapped_column(
        ForeignKey("aditivos.id", ondelete="CASCADE"), nullable=False
    )


class Mixture(db.Model):
    __tablename__ = "mixtures"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(128), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    total_volume: Mapped[float | None] = mapped_column(Float)
    project_id: Mapped[int | None] = mapped_column(
        ForeignKey("projects.id", ondelete="SET NULL", use_alter=True, name="fk_mixtures_project")
    )
    created_at: Mapped[datetime] = mapped_column(default=_now, nullable=False)

    materials: Mapped[list["MixtureMaterial"]] = relationship(
        back_populates="mixture", cascade="all, delete-orphan"
    )


class MixtureMaterial(db.Model):
    __tablename__ = "mixture_materials"
    __table_args__ = (UniqueConstraint("mixture_id", "material_id"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    mixture_id: Mapped[int] = mapped_column(
        ForeignKey("mixtures.id", ondelete="CASCADE"), nullable=False
    )
    material_id: Mapped[int] = mapped_column(
        ForeignKey("materials.id", ondelete="CASCADE"), nullable=False
    )
    quantity: Mapped[float] = mapped_column(Float, nullable=False)
    percentage: Mapped[float | None] = mapped_column(Float)

    mixture: Mapped[Mixture] = relationship(back_populates="materials")
    material: Mapped[Material] = relationship()


class Project(db.Model):
    __tablename__ = "projects"
    __table_args__ = (
        CheckConstraint("resistance_target BETWEEN 24 AND 57", name="ck_resistance_target"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    project_name: Mapped[str] = mapped_column(String(128), nullable=False)
    selected_date: Mapped[str | None] = mapped_column(String(32))
    selected_image_path: Mapped[str | None] = mapped_column(Text)
    creator_name: Mapped[str | None] = mapped_column(String(128))
    tipo_estructura_id: Mapped[int] = mapped_column(
        ForeignKey("tipos_estructura.id", ondelete="RESTRICT"), nullable=False
    )
    resistance_target: Mapped[float] = mapped_column(Float, nullable=False)
    temperature: Mapped[int] = mapped_column(Integer, nullable=False)
    humidity: Mapped[int] = mapped_column(Integer, nullable=False)
    relacion_ac: Mapped[float] = mapped_column(Float, nullable=False)
    aditivo_id: Mapped[int | None] = mapped_column(
        ForeignKey("aditivos.id", ondelete="SET NULL")
    )
    resistencia_predicha_7d: Mapped[float | None] = mapped_column(Float)
    resistencia_predicha_14d: Mapped[float | None] = mapped_column(Float)
    resistencia_predicha_28d: Mapped[float | None] = mapped_column(Float)
    mixture_id: Mapped[int | None] = mapped_column(
        ForeignKey("mixtures.id", ondelete="SET NULL")
    )
    created_at: Mapped[datetime] = mapped_column(default=_now, nullable=False)

    user: Mapped[User] = relationship(back_populates="projects")
    tipo_estructura: Mapped[TipoEstructura] = relationship()
    mixture: Mapped[Mixture | None] = relationship(foreign_keys=[mixture_id])
