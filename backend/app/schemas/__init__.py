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

from app.schemas.documento import (
    DocumentoBase,
    DocumentoCreate,
    DocumentoUpdate,
    DocumentoResponse,
    DocumentoList,
    DocumentoUpload
)

from app.schemas.ampliacion import (
    AmpliacionBase,
    AmpliacionCreate,
    AmpliacionUpdate,
    AmpliacionResponse,
    AmpliacionList,
    ProrrogaBase,
    ProrrogaCreate,
    ProrrogaUpdate,
    ProrrogaResponse,
    ProrrogaList
)

from app.schemas.crm import (
    ContactoBase,
    ContactoCreate,
    ContactoUpdate,
    ContactoResponse,
    ContactoList,
    InteraccionClienteBase,
    InteraccionClienteCreate,
    InteraccionClienteUpdate,
    InteraccionClienteResponse,
    InteraccionClienteList
)

from app.schemas.alerta import (
    AlertaBase,
    AlertaCreate,
    AlertaUpdate,
    AlertaResponse,
    AlertaList,
    AlertaStats,
    ConfiguracionAlertasBase,
    ConfiguracionAlertasCreate,
    ConfiguracionAlertasUpdate,
    ConfiguracionAlertasResponse
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
    "LicitacionStats",
    # Documento schemas
    "DocumentoBase",
    "DocumentoCreate",
    "DocumentoUpdate",
    "DocumentoResponse",
    "DocumentoList",
    "DocumentoUpload",
    # Ampliacion schemas
    "AmpliacionBase",
    "AmpliacionCreate",
    "AmpliacionUpdate",
    "AmpliacionResponse",
    "AmpliacionList",
    # Prorroga schemas
    "ProrrogaBase",
    "ProrrogaCreate",
    "ProrrogaUpdate",
    "ProrrogaResponse",
    "ProrrogaList",
    # CRM schemas
    "ContactoBase",
    "ContactoCreate",
    "ContactoUpdate",
    "ContactoResponse",
    "ContactoList",
    "InteraccionClienteBase",
    "InteraccionClienteCreate",
    "InteraccionClienteUpdate",
    "InteraccionClienteResponse",
    "InteraccionClienteList",
    # Alerta schemas
    "AlertaBase",
    "AlertaCreate",
    "AlertaUpdate",
    "AlertaResponse",
    "AlertaList",
    "AlertaStats",
    "ConfiguracionAlertasBase",
    "ConfiguracionAlertasCreate",
    "ConfiguracionAlertasUpdate",
    "ConfiguracionAlertasResponse"
]
