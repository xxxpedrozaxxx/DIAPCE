"""POST /api/auth/register · POST /api/auth/login"""
import bcrypt
from flask.views import MethodView
from flask_jwt_extended import create_access_token
from flask_smorest import Blueprint, abort
from sqlalchemy import select

from ..extensions import db
from ..models import User
from ..schemas import LoginSchema, RegisterSchema, TokenSchema

blp = Blueprint("auth", __name__, url_prefix="/api/auth", description="Autenticación")


def _hash(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def _check(password: str, password_hash: str) -> bool:
    return bcrypt.checkpw(password.encode(), password_hash.encode())


def _token_response(user: User) -> dict:
    return {"access_token": create_access_token(identity=str(user.id)), "user": user}


@blp.route("/register")
class Register(MethodView):
    @blp.arguments(RegisterSchema)
    @blp.response(201, TokenSchema)
    @blp.doc(security=[])
    def post(self, data):
        """Crea un usuario y devuelve su token."""
        if db.session.scalar(select(User).where(User.email == data["email"])):
            abort(409, message="El usuario ya existe. Usa otro correo.")
        user = User(email=data["email"], password_hash=_hash(data["password"]))
        db.session.add(user)
        db.session.commit()
        return _token_response(user)


@blp.route("/login")
class Login(MethodView):
    @blp.arguments(LoginSchema)
    @blp.response(200, TokenSchema)
    @blp.doc(security=[])
    def post(self, data):
        """Valida credenciales y devuelve un JWT."""
        user = db.session.scalar(select(User).where(User.email == data["email"]))
        if user is None or not _check(data["password"], user.password_hash):
            abort(401, message="Correo o contraseña incorrectos")
        return _token_response(user)
