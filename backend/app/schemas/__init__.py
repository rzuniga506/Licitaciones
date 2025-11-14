"""Pydantic schemas for request/response validation."""

from app.schemas.user import (
    UserBase,
    UserCreate,
    UserUpdate,
    UserResponse,
    Token,
    TokenData,
    LoginRequest
)

from app.schemas.cliente import (
    ClienteBase,
    ClienteCreate,
    ClienteUpdate,
    ClienteResponse,
    ClienteList
)

from app.schemas.licitacion import (
    LicitacionBase,
    LicitacionCreate,
    LicitacionUpdate,
    LicitacionResponse,
    LicitacionList,
    LicitacionStats
)

__all__ = [
    # User schemas
    "UserBase",
    "UserCreate",
    "UserUpdate",
    "UserResponse",
    "Token",
    "TokenData",
    "LoginRequest",
    # Cliente schemas
    "ClienteBase",
    "ClienteCreate",
    "ClienteUpdate",
    "ClienteResponse",
    "ClienteList",
    # Licitacion schemas
    "LicitacionBase",
    "LicitacionCreate",
    "LicitacionUpdate",
    "LicitacionResponse",
    "LicitacionList",
    "LicitacionStats"
]
