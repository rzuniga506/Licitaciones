# FASE 2: Módulo Core de Licitaciones 📄

**Duración estimada**: Sprint 3-4 (2-3 semanas)  
**Objetivo**: Implementar el módulo central de gestión de licitaciones

---

## 📋 Índice
1. [Objetivos de la Fase](#objetivos)
2. [Diseño de Base de Datos](#base-datos)
3. [Implementación Backend](#implementacion-backend)
4. [Implementación Frontend](#implementacion-frontend)
5. [Testing](#testing)
6. [Checklist](#checklist)

---

## 🎯 Objetivos de la Fase {#objetivos}

- ✅ Crear modelo de Licitaciones con todas sus propiedades
- ✅ Implementar CRUD completo de licitaciones
- ✅ Sistema de estados y transiciones
- ✅ Relación con clientes/instituciones
- ✅ Filtros y búsqueda avanzada
- ✅ Ordenamiento por múltiples criterios
- ✅ Vista de lista con paginación
- ✅ Vista de detalle completa
- ✅ Formulario de creación/edición

---

## 🗄️ Diseño de Base de Datos {#base-datos}

### Tabla de Clientes

```sql
-- Tabla de clientes/instituciones
CREATE TABLE clientes (
    cliente_id SERIAL PRIMARY KEY,
    nombre_cliente VARCHAR(255) NOT NULL,
    tipo_cliente VARCHAR(50) NOT NULL, -- 'publico', 'privado'
    identificacion VARCHAR(50) UNIQUE,
    telefono VARCHAR(50),
    email VARCHAR(255),
    direccion TEXT,
    contacto_principal VARCHAR(255),
    notas TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER REFERENCES users(user_id)
);

CREATE INDEX idx_clientes_nombre ON clientes(nombre_cliente);
CREATE INDEX idx_clientes_tipo ON clientes(tipo_cliente);
```

### Tabla de Licitaciones

```sql
-- Tabla principal de licitaciones
CREATE TABLE licitaciones (
    licitacion_id SERIAL PRIMARY KEY,
    numero_licitacion VARCHAR(100) UNIQUE NOT NULL,
    
    -- Relaciones
    cliente_id INTEGER REFERENCES clientes(cliente_id),
    
    -- Información básica
    nombre_licitacion VARCHAR(500) NOT NULL,
    descripcion TEXT,
    objeto_contrato TEXT,
    
    -- Montos
    monto_ofertado DECIMAL(15, 2),
    monto_adjudicado DECIMAL(15, 2),
    moneda VARCHAR(10) DEFAULT 'CRC', -- CRC, USD, EUR
    
    -- Estado
    estado_licitacion VARCHAR(50) NOT NULL DEFAULT 'en_preparacion',
    -- Estados: en_preparacion, presentada, en_evaluacion, adjudicada, 
    --          en_ejecucion, finalizada, desierta, rechazada
    
    -- Fechas importantes
    fecha_publicacion DATE,
    fecha_presentacion DATE,
    fecha_apertura DATE,
    fecha_adjudicacion DATE,
    fecha_inicio_contrato DATE,
    fecha_fin_contrato DATE,
    
    -- Información adicional
    tipo_licitacion VARCHAR(50), -- 'publica', 'privada', 'abreviada', 'internacional'
    categoria VARCHAR(100), -- 'servicios', 'obras', 'bienes', 'consultoria'
    prioridad VARCHAR(20) DEFAULT 'media', -- 'alta', 'media', 'baja'
    
    -- Enlaces
    url_portal_compras TEXT,
    numero_expediente VARCHAR(100),
    
    -- Garantías
    monto_garantia_participacion DECIMAL(15, 2),
    fecha_vence_garantia_participacion DATE,
    monto_garantia_cumplimiento DECIMAL(15, 2),
    fecha_vence_garantia_cumplimiento DATE,
    
    -- Observaciones
    observaciones TEXT,
    motivo_rechazo TEXT,
    
    -- Auditoría
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER REFERENCES users(user_id),
    updated_by INTEGER REFERENCES users(user_id)
);

-- Índices
CREATE INDEX idx_licitaciones_numero ON licitaciones(numero_licitacion);
CREATE INDEX idx_licitaciones_cliente ON licitaciones(cliente_id);
CREATE INDEX idx_licitaciones_estado ON licitaciones(estado_licitacion);
CREATE INDEX idx_licitaciones_categoria ON licitaciones(categoria);
CREATE INDEX idx_licitaciones_fecha_presentacion ON licitaciones(fecha_presentacion);
CREATE INDEX idx_licitaciones_fecha_fin ON licitaciones(fecha_fin_contrato);
```

### Diagrama de Relaciones

```
┌─────────────┐          ┌──────────────────┐
│   users     │──────────│   licitaciones   │
│  (Fase 1)   │ created  │                  │
└─────────────┘    by    └──────────────────┘
                               │
                               │ cliente_id
                               ▼
                         ┌─────────────┐
                         │  clientes   │
                         └─────────────┘
```

---

## 💻 Implementación Backend {#implementacion-backend}

### 1. Modelo de Cliente

**app/models/cliente.py**
```python
from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base

class Cliente(Base):
    __tablename__ = "clientes"
    
    cliente_id = Column(Integer, primary_key=True, index=True)
    nombre_cliente = Column(String(255), nullable=False, index=True)
    tipo_cliente = Column(String(50), nullable=False)  # publico, privado
    identificacion = Column(String(50), unique=True)
    telefono = Column(String(50))
    email = Column(String(255))
    direccion = Column(Text)
    contacto_principal = Column(String(255))
    notas = Column(Text)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    created_by = Column(Integer, ForeignKey("users.user_id"))
    
    # Relaciones
    licitaciones = relationship("Licitacion", back_populates="cliente")
```

### 2. Modelo de Licitación

**app/models/licitacion.py**
```python
from sqlalchemy import Column, Integer, String, Text, Numeric, Date, DateTime, Boolean, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base

class Licitacion(Base):
    __tablename__ = "licitaciones"
    
    licitacion_id = Column(Integer, primary_key=True, index=True)
    numero_licitacion = Column(String(100), unique=True, nullable=False, index=True)
    
    # Relaciones
    cliente_id = Column(Integer, ForeignKey("clientes.cliente_id"))
    
    # Información básica
    nombre_licitacion = Column(String(500), nullable=False)
    descripcion = Column(Text)
    objeto_contrato = Column(Text)
    
    # Montos
    monto_ofertado = Column(Numeric(15, 2))
    monto_adjudicado = Column(Numeric(15, 2))
    moneda = Column(String(10), default="CRC")
    
    # Estado
    estado_licitacion = Column(String(50), nullable=False, default="en_preparacion", index=True)
    
    # Fechas
    fecha_publicacion = Column(Date)
    fecha_presentacion = Column(Date, index=True)
    fecha_apertura = Column(Date)
    fecha_adjudicacion = Column(Date)
    fecha_inicio_contrato = Column(Date)
    fecha_fin_contrato = Column(Date, index=True)
    
    # Clasificación
    tipo_licitacion = Column(String(50))
    categoria = Column(String(100), index=True)
    prioridad = Column(String(20), default="media")
    
    # Enlaces
    url_portal_compras = Column(Text)
    numero_expediente = Column(String(100))
    
    # Garantías
    monto_garantia_participacion = Column(Numeric(15, 2))
    fecha_vence_garantia_participacion = Column(Date)
    monto_garantia_cumplimiento = Column(Numeric(15, 2))
    fecha_vence_garantia_cumplimiento = Column(Date)
    
    # Observaciones
    observaciones = Column(Text)
    motivo_rechazo = Column(Text)
    
    # Auditoría
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    created_by = Column(Integer, ForeignKey("users.user_id"))
    updated_by = Column(Integer, ForeignKey("users.user_id"))
    
    # Relaciones
    cliente = relationship("Cliente", back_populates="licitaciones")
```

### 3. Schemas Pydantic

**app/schemas/cliente.py**
```python
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class ClienteBase(BaseModel):
    nombre_cliente: str = Field(..., max_length=255)
    tipo_cliente: str = Field(..., pattern="^(publico|privado)$")
    identificacion: Optional[str] = Field(None, max_length=50)
    telefono: Optional[str] = None
    email: Optional[EmailStr] = None
    direccion: Optional[str] = None
    contacto_principal: Optional[str] = None
    notas: Optional[str] = None

class ClienteCreate(ClienteBase):
    pass

class ClienteUpdate(BaseModel):
    nombre_cliente: Optional[str] = None
    tipo_cliente: Optional[str] = None
    telefono: Optional[str] = None
    email: Optional[EmailStr] = None
    direccion: Optional[str] = None
    contacto_principal: Optional[str] = None
    notas: Optional[str] = None
    is_active: Optional[bool] = None

class ClienteResponse(ClienteBase):
    cliente_id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime]
    
    class Config:
        from_attributes = True
```

**app/schemas/licitacion.py**
```python
from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import date, datetime
from decimal import Decimal

class LicitacionBase(BaseModel):
    numero_licitacion: str = Field(..., max_length=100)
    cliente_id: Optional[int] = None
    nombre_licitacion: str = Field(..., max_length=500)
    descripcion: Optional[str] = None
    objeto_contrato: Optional[str] = None
    monto_ofertado: Optional[Decimal] = None
    monto_adjudicado: Optional[Decimal] = None
    moneda: str = Field(default="CRC", max_length=10)
    estado_licitacion: str = Field(default="en_preparacion")
    fecha_publicacion: Optional[date] = None
    fecha_presentacion: Optional[date] = None
    fecha_apertura: Optional[date] = None
    fecha_adjudicacion: Optional[date] = None
    fecha_inicio_contrato: Optional[date] = None
    fecha_fin_contrato: Optional[date] = None
    tipo_licitacion: Optional[str] = None
    categoria: Optional[str] = None
    prioridad: str = Field(default="media")
    url_portal_compras: Optional[str] = None
    numero_expediente: Optional[str] = None
    monto_garantia_participacion: Optional[Decimal] = None
    fecha_vence_garantia_participacion: Optional[date] = None
    monto_garantia_cumplimiento: Optional[Decimal] = None
    fecha_vence_garantia_cumplimiento: Optional[date] = None
    observaciones: Optional[str] = None

    @validator('estado_licitacion')
    def validate_estado(cls, v):
        estados_validos = [
            'en_preparacion', 'presentada', 'en_evaluacion', 'adjudicada',
            'en_ejecucion', 'finalizada', 'desierta', 'rechazada'
        ]
        if v not in estados_validos:
            raise ValueError(f'Estado debe ser uno de: {", ".join(estados_validos)}')
        return v

class LicitacionCreate(LicitacionBase):
    pass

class LicitacionUpdate(BaseModel):
    nombre_licitacion: Optional[str] = None
    descripcion: Optional[str] = None
    cliente_id: Optional[int] = None
    monto_ofertado: Optional[Decimal] = None
    monto_adjudicado: Optional[Decimal] = None
    estado_licitacion: Optional[str] = None
    fecha_presentacion: Optional[date] = None
    fecha_apertura: Optional[date] = None
    fecha_adjudicacion: Optional[date] = None
    fecha_inicio_contrato: Optional[date] = None
    fecha_fin_contrato: Optional[date] = None
    categoria: Optional[str] = None
    prioridad: Optional[str] = None
    observaciones: Optional[str] = None
    is_active: Optional[bool] = None

class LicitacionResponse(LicitacionBase):
    licitacion_id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime]
    created_by: int
    updated_by: Optional[int]
    
    # Relación con cliente
    cliente: Optional["ClienteResponse"] = None
    
    class Config:
        from_attributes = True

# Para evitar errores de importación circular
from app.schemas.cliente import ClienteResponse
LicitacionResponse.model_rebuild()
```

### 4. Enums y Utilidades

**app/utils/enums.py**
```python
from enum import Enum

class EstadoLicitacion(str, Enum):
    EN_PREPARACION = "en_preparacion"
    PRESENTADA = "presentada"
    EN_EVALUACION = "en_evaluacion"
    ADJUDICADA = "adjudicada"
    EN_EJECUCION = "en_ejecucion"
    FINALIZADA = "finalizada"
    DESIERTA = "desierta"
    RECHAZADA = "rechazada"

class TipoCliente(str, Enum):
    PUBLICO = "publico"
    PRIVADO = "privado"

class Prioridad(str, Enum):
    ALTA = "alta"
    MEDIA = "media"
    BAJA = "baja"

class TipoLicitacion(str, Enum):
    PUBLICA = "publica"
    PRIVADA = "privada"
    ABREVIADA = "abreviada"
    INTERNACIONAL = "internacional"

class Categoria(str, Enum):
    SERVICIOS = "servicios"
    OBRAS = "obras"
    BIENES = "bienes"
    CONSULTORIA = "consultoria"
```

### 5. Service Layer

**app/services/licitacion_service.py**
```python
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from typing import List, Optional
from datetime import date

from app.models.licitacion import Licitacion
from app.schemas.licitacion import LicitacionCreate, LicitacionUpdate

class LicitacionService:
    
    @staticmethod
    def get_licitaciones(
        db: Session,
        skip: int = 0,
        limit: int = 100,
        estado: Optional[str] = None,
        cliente_id: Optional[int] = None,
        categoria: Optional[str] = None,
        search: Optional[str] = None,
        fecha_desde: Optional[date] = None,
        fecha_hasta: Optional[date] = None,
        order_by: str = "fecha_presentacion",
        order_direction: str = "desc"
    ) -> List[Licitacion]:
        """Obtener licitaciones con filtros avanzados"""
        
        query = db.query(Licitacion).filter(Licitacion.is_active == True)
        
        # Filtros
        if estado:
            query = query.filter(Licitacion.estado_licitacion == estado)
        
        if cliente_id:
            query = query.filter(Licitacion.cliente_id == cliente_id)
        
        if categoria:
            query = query.filter(Licitacion.categoria == categoria)
        
        if search:
            query = query.filter(
                or_(
                    Licitacion.numero_licitacion.ilike(f"%{search}%"),
                    Licitacion.nombre_licitacion.ilike(f"%{search}%"),
                    Licitacion.descripcion.ilike(f"%{search}%")
                )
            )
        
        if fecha_desde:
            query = query.filter(Licitacion.fecha_presentacion >= fecha_desde)
        
        if fecha_hasta:
            query = query.filter(Licitacion.fecha_presentacion <= fecha_hasta)
        
        # Ordenamiento
        if order_direction == "desc":
            query = query.order_by(getattr(Licitacion, order_by).desc())
        else:
            query = query.order_by(getattr(Licitacion, order_by).asc())
        
        return query.offset(skip).limit(limit).all()
    
    @staticmethod
    def get_licitacion_by_id(db: Session, licitacion_id: int) -> Optional[Licitacion]:
        return db.query(Licitacion).filter(
            Licitacion.licitacion_id == licitacion_id,
            Licitacion.is_active == True
        ).first()
    
    @staticmethod
    def create_licitacion(
        db: Session,
        licitacion_data: LicitacionCreate,
        user_id: int
    ) -> Licitacion:
        db_licitacion = Licitacion(
            **licitacion_data.model_dump(),
            created_by=user_id
        )
        db.add(db_licitacion)
        db.commit()
        db.refresh(db_licitacion)
        return db_licitacion
    
    @staticmethod
    def update_licitacion(
        db: Session,
        licitacion_id: int,
        licitacion_data: LicitacionUpdate,
        user_id: int
    ) -> Optional[Licitacion]:
        licitacion = LicitacionService.get_licitacion_by_id(db, licitacion_id)
        if not licitacion:
            return None
        
        update_data = licitacion_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(licitacion, field, value)
        
        licitacion.updated_by = user_id
        db.commit()
        db.refresh(licitacion)
        return licitacion
    
    @staticmethod
    def delete_licitacion(db: Session, licitacion_id: int) -> bool:
        licitacion = LicitacionService.get_licitacion_by_id(db, licitacion_id)
        if not licitacion:
            return False
        
        licitacion.is_active = False
        db.commit()
        return True
    
    @staticmethod
    def get_estadisticas(db: Session) -> dict:
        """Obtener estadísticas generales"""
        total = db.query(Licitacion).filter(Licitacion.is_active == True).count()
        
        por_estado = {}
        for estado in ['en_preparacion', 'presentada', 'adjudicada', 'en_ejecucion', 'finalizada']:
            count = db.query(Licitacion).filter(
                Licitacion.is_active == True,
                Licitacion.estado_licitacion == estado
            ).count()
            por_estado[estado] = count
        
        return {
            "total": total,
            "por_estado": por_estado
        }
```

### 6. Endpoints de Licitaciones

**app/api/v1/endpoints/licitaciones.py**
```python
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date

from app.database import get_db
from app.models.user import User
from app.schemas.licitacion import LicitacionCreate, LicitacionUpdate, LicitacionResponse
from app.services.licitacion_service import LicitacionService
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/", response_model=List[LicitacionResponse])
def get_licitaciones(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    estado: Optional[str] = None,
    cliente_id: Optional[int] = None,
    categoria: Optional[str] = None,
    search: Optional[str] = None,
    fecha_desde: Optional[date] = None,
    fecha_hasta: Optional[date] = None,
    order_by: str = Query("fecha_presentacion"),
    order_direction: str = Query("desc", regex="^(asc|desc)$"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Listar licitaciones con filtros avanzados"""
    licitaciones = LicitacionService.get_licitaciones(
        db=db,
        skip=skip,
        limit=limit,
        estado=estado,
        cliente_id=cliente_id,
        categoria=categoria,
        search=search,
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
        order_by=order_by,
        order_direction=order_direction
    )
    return licitaciones

@router.get("/estadisticas")
def get_estadisticas(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Obtener estadísticas de licitaciones"""
    return LicitacionService.get_estadisticas(db)

@router.get("/{licitacion_id}", response_model=LicitacionResponse)
def get_licitacion(
    licitacion_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Obtener una licitación por ID"""
    licitacion = LicitacionService.get_licitacion_by_id(db, licitacion_id)
    if not licitacion:
        raise HTTPException(status_code=404, detail="Licitación no encontrada")
    return licitacion

@router.post("/", response_model=LicitacionResponse, status_code=201)
def create_licitacion(
    licitacion_data: LicitacionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Crear nueva licitación"""
    try:
        licitacion = LicitacionService.create_licitacion(
            db=db,
            licitacion_data=licitacion_data,
            user_id=current_user.user_id
        )
        return licitacion
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.put("/{licitacion_id}", response_model=LicitacionResponse)
def update_licitacion(
    licitacion_id: int,
    licitacion_data: LicitacionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Actualizar licitación"""
    licitacion = LicitacionService.update_licitacion(
        db=db,
        licitacion_id=licitacion_id,
        licitacion_data=licitacion_data,
        user_id=current_user.user_id
    )
    if not licitacion:
        raise HTTPException(status_code=404, detail="Licitación no encontrada")
    return licitacion

@router.delete("/{licitacion_id}", status_code=204)
def delete_licitacion(
    licitacion_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Eliminar licitación (soft delete)"""
    success = LicitacionService.delete_licitacion(db, licitacion_id)
    if not success:
        raise HTTPException(status_code=404, detail="Licitación no encontrada")
    return None
```

### 7. Endpoints de Clientes

**app/api/v1/endpoints/clientes.py**
```python
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.models.user import User
from app.models.cliente import Cliente
from app.schemas.cliente import ClienteCreate, ClienteUpdate, ClienteResponse
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/", response_model=List[ClienteResponse])
def get_clientes(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    tipo: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Listar clientes"""
    query = db.query(Cliente).filter(Cliente.is_active == True)
    
    if tipo:
        query = query.filter(Cliente.tipo_cliente == tipo)
    
    if search:
        query = query.filter(Cliente.nombre_cliente.ilike(f"%{search}%"))
    
    clientes = query.offset(skip).limit(limit).all()
    return clientes

@router.get("/{cliente_id}", response_model=ClienteResponse)
def get_cliente(
    cliente_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Obtener cliente por ID"""
    cliente = db.query(Cliente).filter(
        Cliente.cliente_id == cliente_id,
        Cliente.is_active == True
    ).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    return cliente

@router.post("/", response_model=ClienteResponse, status_code=201)
def create_cliente(
    cliente_data: ClienteCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Crear nuevo cliente"""
    db_cliente = Cliente(
        **cliente_data.model_dump(),
        created_by=current_user.user_id
    )
    db.add(db_cliente)
    db.commit()
    db.refresh(db_cliente)
    return db_cliente

@router.put("/{cliente_id}", response_model=ClienteResponse)
def update_cliente(
    cliente_id: int,
    cliente_data: ClienteUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Actualizar cliente"""
    cliente = db.query(Cliente).filter(Cliente.cliente_id == cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    
    update_data = cliente_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(cliente, field, value)
    
    db.commit()
    db.refresh(cliente)
    return cliente

@router.delete("/{cliente_id}", status_code=204)
def delete_cliente(
    cliente_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Eliminar cliente (soft delete)"""
    cliente = db.query(Cliente).filter(Cliente.cliente_id == cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    
    cliente.is_active = False
    db.commit()
    return None
```

### 8. Actualizar Router Principal

**app/api/v1/__init__.py**
```python
from fastapi import APIRouter
from app.api.v1.endpoints import auth, users, licitaciones, clientes

router = APIRouter()

router.include_router(auth.router, prefix="/auth", tags=["Autenticación"])
router.include_router(users.router, prefix="/users", tags=["Usuarios"])
router.include_router(licitaciones.router, prefix="/licitaciones", tags=["Licitaciones"])
router.include_router(clientes.router, prefix="/clientes", tags=["Clientes"])
```

---

## 📱 Implementación Frontend {#implementacion-frontend}

### 1. Modelos Flutter

**lib/data/models/cliente_model.dart**
```dart
import 'package:json_annotation/json_annotation.dart';

part 'cliente_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ClienteModel {
  final int clienteId;
  final String nombreCliente;
  final String tipoCliente;
  final String? identificacion;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? contactoPrincipal;
  final String? notas;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ClienteModel({
    required this.clienteId,
    required this.nombreCliente,
    required this.tipoCliente,
    this.identificacion,
    this.telefono,
    this.email,
    this.direccion,
    this.contactoPrincipal,
    this.notas,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) =>
      _$ClienteModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClienteModelToJson(this);
}
```

**lib/data/models/licitacion_model.dart**
```dart
import 'package:json_annotation/json_annotation.dart';
import 'cliente_model.dart';

part 'licitacion_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class LicitacionModel {
  final int licitacionId;
  final String numeroLicitacion;
  final int? clienteId;
  final String nombreLicitacion;
  final String? descripcion;
  final String? objetoContrato;
  final double? montoOfertado;
  final double? montoAdjudicado;
  final String moneda;
  final String estadoLicitacion;
  final DateTime? fechaPublicacion;
  final DateTime? fechaPresentacion;
  final DateTime? fechaApertura;
  final DateTime? fechaAdjudicacion;
  final DateTime? fechaInicioContrato;
  final DateTime? fechaFinContrato;
  final String? tipoLicitacion;
  final String? categoria;
  final String prioridad;
  final String? urlPortalCompras;
  final String? numeroExpediente;
  final double? montoGarantiaParticipacion;
  final DateTime? fechaVenceGarantiaParticipacion;
  final double? montoGarantiaCumplimiento;
  final DateTime? fechaVenceGarantiaCumplimiento;
  final String? observaciones;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int createdBy;
  final int? updatedBy;
  final ClienteModel? cliente;

  LicitacionModel({
    required this.licitacionId,
    required this.numeroLicitacion,
    this.clienteId,
    required this.nombreLicitacion,
    this.descripcion,
    this.objetoContrato,
    this.montoOfertado,
    this.montoAdjudicado,
    required this.moneda,
    required this.estadoLicitacion,
    this.fechaPublicacion,
    this.fechaPresentacion,
    this.fechaApertura,
    this.fechaAdjudicacion,
    this.fechaInicioContrato,
    this.fechaFinContrato,
    this.tipoLicitacion,
    this.categoria,
    required this.prioridad,
    this.urlPortalCompras,
    this.numeroExpediente,
    this.montoGarantiaParticipacion,
    this.fechaVenceGarantiaParticipacion,
    this.montoGarantiaCumplimiento,
    this.fechaVenceGarantiaCumplimiento,
    this.observaciones,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.updatedBy,
    this.cliente,
  });

  factory LicitacionModel.fromJson(Map<String, dynamic> json) =>
      _$LicitacionModelFromJson(json);

  Map<String, dynamic> toJson() => _$LicitacionModelToJson(this);
  
  String get estadoFormatted {
    final estados = {
      'en_preparacion': 'En Preparación',
      'presentada': 'Presentada',
      'en_evaluacion': 'En Evaluación',
      'adjudicada': 'Adjudicada',
      'en_ejecucion': 'En Ejecución',
      'finalizada': 'Finalizada',
      'desierta': 'Desierta',
      'rechazada': 'Rechazada',
    };
    return estados[estadoLicitacion] ?? estadoLicitacion;
  }
  
  Color getEstadoColor() {
    switch (estadoLicitacion) {
      case 'en_preparacion':
        return Colors.grey;
      case 'presentada':
        return Colors.blue;
      case 'adjudicada':
        return Colors.green;
      case 'en_ejecucion':
        return Colors.orange;
      case 'finalizada':
        return Colors.teal;
      case 'rechazada':
      case 'desierta':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
```

### 2. Repository de Licitaciones

**lib/data/repositories/licitacion_repository.dart**
```dart
import '../data_sources/api_client.dart';
import '../models/licitacion_model.dart';
import '../../core/config/api_config.dart';

class LicitacionRepository {
  final ApiClient _apiClient;

  LicitacionRepository(this._apiClient);

  Future<List<LicitacionModel>> getLicitaciones({
    int skip = 0,
    int limit = 100,
    String? estado,
    int? clienteId,
    String? categoria,
    String? search,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String orderBy = 'fecha_presentacion',
    String orderDirection = 'desc',
  }) async {
    try {
      final queryParams = {
        'skip': skip.toString(),
        'limit': limit.toString(),
        'order_by': orderBy,
        'order_direction': orderDirection,
      };

      if (estado != null) queryParams['estado'] = estado;
      if (clienteId != null) queryParams['cliente_id'] = clienteId.toString();
      if (categoria != null) queryParams['categoria'] = categoria;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (fechaDesde != null) {
        queryParams['fecha_desde'] = fechaDesde.toIso8601String().split('T')[0];
      }
      if (fechaHasta != null) {
        queryParams['fecha_hasta'] = fechaHasta.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.dio.get(
        ApiConfig.licitaciones,
        queryParameters: queryParams,
      );

      return (response.data as List)
          .map((json) => LicitacionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener licitaciones: $e');
    }
  }

  Future<LicitacionModel> getLicitacion(int licitacionId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConfig.licitaciones}/$licitacionId',
      );
      return LicitacionModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener licitación: $e');
    }
  }

  Future<LicitacionModel> createLicitacion(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.licitaciones,
        data: data,
      );
      return LicitacionModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear licitación: $e');
    }
  }

  Future<LicitacionModel> updateLicitacion(
    int licitacionId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConfig.licitaciones}/$licitacionId',
        data: data,
      );
      return LicitacionModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar licitación: $e');
    }
  }

  Future<void> deleteLicitacion(int licitacionId) async {
    try {
      await _apiClient.dio.delete(
        '${ApiConfig.licitaciones}/$licitacionId',
      );
    } catch (e) {
      throw Exception('Error al eliminar licitación: $e');
    }
  }

  Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConfig.licitaciones}/estadisticas',
      );
      return response.data;
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}
```

### 3. Pantalla de Lista de Licitaciones

**lib/presentation/screens/licitaciones/licitaciones_list_screen.dart**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';

class LicitacionesListScreen extends ConsumerStatefulWidget {
  const LicitacionesListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LicitacionesListScreen> createState() =>
      _LicitacionesListScreenState();
}

class _LicitacionesListScreenState
    extends ConsumerState<LicitacionesListScreen> {
  final _searchController = TextEditingController();
  String? _selectedEstado;
  String? _selectedCategoria;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Licitaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por número o nombre...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Chips de filtros activos
          if (_selectedEstado != null || _selectedCategoria != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedEstado != null)
                    Chip(
                      label: Text(_selectedEstado!),
                      onDeleted: () => setState(() => _selectedEstado = null),
                    ),
                  if (_selectedCategoria != null)
                    Chip(
                      label: Text(_selectedCategoria!),
                      onDeleted: () =>
                          setState(() => _selectedCategoria = null),
                    ),
                ],
              ),
            ),

          // Lista de licitaciones
          Expanded(
            child: FutureBuilder(
              // Aquí integrarías con tu provider/repository
              future: Future.delayed(Duration(seconds: 1)), // Simulación
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }

                // Lista simulada
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return _LicitacionCard(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/licitacion-detail',
                          arguments: index,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/licitacion-form');
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Licitación'),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedEstado,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: const [
                DropdownMenuItem(
                    value: 'en_preparacion', child: Text('En Preparación')),
                DropdownMenuItem(
                    value: 'presentada', child: Text('Presentada')),
                DropdownMenuItem(
                    value: 'adjudicada', child: Text('Adjudicada')),
                DropdownMenuItem(
                    value: 'en_ejecucion', child: Text('En Ejecución')),
                DropdownMenuItem(
                    value: 'finalizada', child: Text('Finalizada')),
              ],
              onChanged: (value) {
                setState(() => _selectedEstado = value);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: const [
                DropdownMenuItem(
                    value: 'servicios', child: Text('Servicios')),
                DropdownMenuItem(value: 'obras', child: Text('Obras')),
                DropdownMenuItem(value: 'bienes', child: Text('Bienes')),
                DropdownMenuItem(
                    value: 'consultoria', child: Text('Consultoría')),
              ],
              onChanged: (value) {
                setState(() => _selectedCategoria = value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedEstado = null;
                _selectedCategoria = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _LicitacionCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LicitacionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LIC-2025-001',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Servicios de Consultoría TI',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Adjudicada',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Ministerio de Educación',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '₡50,000,000.00',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '15/03/2025',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 4. Pantalla de Detalle de Licitación

**lib/presentation/screens/licitaciones/licitacion_detail_screen.dart**
```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LicitacionDetailScreen extends StatelessWidget {
  final int licitacionId;

  const LicitacionDetailScreen({
    Key? key,
    required this.licitacionId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Licitación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/licitacion-form',
                arguments: licitacionId,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con estado
            _buildHeader(context),
            const SizedBox(height: 24),

            // Información general
            _buildSection(
              context,
              title: 'Información General',
              children: [
                _buildInfoRow('Número', 'LIC-2025-001'),
                _buildInfoRow('Cliente', 'Ministerio de Educación'),
                _buildInfoRow('Categoría', 'Servicios'),
                _buildInfoRow('Prioridad', 'Alta', color: Colors.red),
              ],
            ),
            const SizedBox(height: 24),

            // Descripción
            _buildSection(
              context,
              title: 'Descripción',
              children: [
                Text(
                  'Servicios de consultoría especializada en tecnologías de información para la implementación de sistemas educativos.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Montos
            _buildSection(
              context,
              title: 'Información Financiera',
              children: [
                _buildInfoRow('Monto Ofertado', '₡45,000,000.00'),
                _buildInfoRow('Monto Adjudicado', '₡50,000,000.00',
                    color: Colors.green),
                _buildInfoRow('Moneda', 'CRC'),
              ],
            ),
            const SizedBox(height: 24),

            // Fechas importantes
            _buildSection(
              context,
              title: 'Fechas Importantes',
              children: [
                _buildInfoRow('Publicación', '01/01/2025'),
                _buildInfoRow('Presentación', '15/02/2025'),
                _buildInfoRow('Adjudicación', '01/03/2025'),
                _buildInfoRow('Inicio Contrato', '15/03/2025'),
                _buildInfoRow('Fin Contrato', '15/03/2026', color: Colors.orange),
              ],
            ),
            const SizedBox(height: 24),

            // Garantías
            _buildSection(
              context,
              title: 'Garantías',
              children: [
                _buildInfoRow('Garantía Participación', '₡2,500,000.00'),
                _buildInfoRow('Vence', '15/02/2025'),
                const Divider(height: 24),
                _buildInfoRow('Garantía Cumplimiento', '₡5,000,000.00'),
                _buildInfoRow('Vence', '15/03/2026', color: Colors.orange),
              ],
            ),
            const SizedBox(height: 24),

            // Observaciones
            _buildSection(
              context,
              title: 'Observaciones',
              children: [
                Text(
                  'Licitación adjudicada exitosamente. Pendiente firma de contrato.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Adjudicada',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'LIC-2025-001',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Servicios de Consultoría TI',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.file_copy),
            title: const Text('Duplicar'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.archive),
            title: const Text('Archivar'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
```

### 5. Formulario de Licitación

**lib/presentation/screens/licitaciones/licitacion_form_screen.dart**
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LicitacionFormScreen extends StatefulWidget {
  final int? licitacionId; // null = crear, int = editar

  const LicitacionFormScreen({Key? key, this.licitacionId}) : super(key: key);

  @override
  State<LicitacionFormScreen> createState() => _LicitacionFormScreenState();
}

class _LicitacionFormScreenState extends State<LicitacionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _montoOfertadoController = TextEditingController();
  
  String? _selectedEstado = 'en_preparacion';
  String? _selectedCategoria;
  String? _selectedPrioridad = 'media';
  DateTime? _fechaPresentacion;
  bool _isLoading = false;

  @override
  void dispose() {
    _numeroController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _montoOfertadoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.licitacionId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Licitación' : 'Nueva Licitación'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Número de licitación
            TextFormField(
              controller: _numeroController,
              decoration: const InputDecoration(
                labelText: 'Número de Licitación *',
                hintText: 'LIC-2025-001',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Nombre
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Licitación *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Estado
            DropdownButtonFormField<String>(
              value: _selectedEstado,
              decoration: const InputDecoration(
                labelText: 'Estado *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'en_preparacion', child: Text('En Preparación')),
                DropdownMenuItem(value: 'presentada', child: Text('Presentada')),
                DropdownMenuItem(value: 'en_evaluacion', child: Text('En Evaluación')),
                DropdownMenuItem(value: 'adjudicada', child: Text('Adjudicada')),
                DropdownMenuItem(value: 'en_ejecucion', child: Text('En Ejecución')),
                DropdownMenuItem(value: 'finalizada', child: Text('Finalizada')),
              ],
              onChanged: (value) => setState(() => _selectedEstado = value),
            ),
            const SizedBox(height: 16),

            // Categoría
            DropdownButtonFormField<String>(
              value: _selectedCategoria,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'servicios', child: Text('Servicios')),
                DropdownMenuItem(value: 'obras', child: Text('Obras')),
                DropdownMenuItem(value: 'bienes', child: Text('Bienes')),
                DropdownMenuItem(value: 'consultoria', child: Text('Consultoría')),
              ],
              onChanged: (value) => setState(() => _selectedCategoria = value),
            ),
            const SizedBox(height: 16),

            // Prioridad
            DropdownButtonFormField<String>(
              value: _selectedPrioridad,
              decoration: const InputDecoration(
                labelText: 'Prioridad',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'alta', child: Text('Alta')),
                DropdownMenuItem(value: 'media', child: Text('Media')),
                DropdownMenuItem(value: 'baja', child: Text('Baja')),
              ],
              onChanged: (value) => setState(() => _selectedPrioridad = value),
            ),
            const SizedBox(height: 16),

            // Monto ofertado
            TextFormField(
              controller: _montoOfertadoController,
              decoration: const InputDecoration(
                labelText: 'Monto Ofertado',
                prefixText: '₡ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Fecha de presentación
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de Presentación',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _fechaPresentacion != null
                      ? '${_fechaPresentacion!.day}/${_fechaPresentacion!.month}/${_fechaPresentacion!.year}'
                      : 'Seleccionar fecha',
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Guardar' : 'Crear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaPresentacion ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _fechaPresentacion = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Aquí integrarías con tu repository
      await Future.delayed(const Duration(seconds: 1)); // Simulación

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Licitación guardada exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
```

---

## 🧪 Testing {#testing}

### Backend Tests

**tests/test_licitaciones.py**
```python
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_create_licitacion(auth_token):
    response = client.post(
        "/api/v1/licitaciones/",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "numero_licitacion": "LIC-TEST-001",
            "nombre_licitacion": "Licitación de Prueba",
            "estado_licitacion": "en_preparacion",
            "moneda": "CRC",
            "prioridad": "media"
        }
    )
    assert response.status_code == 201
    assert response.json()["numero_licitacion"] == "LIC-TEST-001"

def test_get_licitaciones(auth_token):
    response = client.get(
        "/api/v1/licitaciones/",
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_filter_by_estado(auth_token):
    response = client.get(
        "/api/v1/licitaciones/?estado=adjudicada",
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert response.status_code == 200
    for licitacion in response.json():
        assert licitacion["estado_licitacion"] == "adjudicada"
```

---

## ✅ Checklist de Completitud {#checklist}

### Backend
- [ ] Modelos Cliente y Licitacion creados
- [ ] Migraciones de base de datos aplicadas
- [ ] Schemas Pydantic con validaciones
- [ ] Enums para estados, categorías, etc.
- [ ] Service layer con lógica de negocio
- [ ] Endpoints CRUD de clientes
- [ ] Endpoints CRUD de licitaciones
- [ ] Filtros avanzados funcionando
- [ ] Búsqueda por texto
- [ ] Ordenamiento por múltiples campos
- [ ] Paginación implementada
- [ ] Estadísticas generales
- [ ] Validaciones de estados
- [ ] Soft delete implementado
- [ ] Tests unitarios pasando

### Frontend
- [ ] Modelos Cliente y Licitacion
- [ ] Repositories implementados
- [ ] Pantalla de lista con búsqueda
- [ ] Filtros por estado y categoría
- [ ] Pantalla de detalle completa
- [ ] Formulario de creación/edición
- [ ] Validaciones de formulario
- [ ] Date picker funcionando
- [ ] Manejo de estados de carga
- [ ] Manejo de errores
- [ ] Navegación entre pantallas
- [ ] Cards con información clara
- [ ] Diseño responsive

### Integración
- [ ] CRUD completo funcionando
- [ ] Filtros sincronizados con backend
- [ ] Búsqueda en tiempo real
- [ ] Creación de licitaciones
- [ ] Edición de licitaciones
- [ ] Eliminación (soft delete)
- [ ] Visualización de detalles
- [ ] Formato de moneda correcto
- [ ] Formato de fechas correcto

---

## 🚀 Comandos de Ejecución

### Migración de Base de Datos
```bash
# Crear migración
alembic revision --autogenerate -m "Add licitaciones and clientes tables"

# Aplicar migración
alembic upgrade head

# Rollback (si es necesario)
alembic downgrade -1
```

### Generar modelos Flutter
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📊 Criterios de Aceptación

1. ✅ Usuario puede crear una licitación con campos básicos
2. ✅ Usuario puede editar una licitación existente
3. ✅ Usuario puede eliminar una licitación (soft delete)
4. ✅ Usuario puede filtrar por estado, categoría y cliente
5. ✅ Usuario puede buscar por número o nombre
6. ✅ Lista muestra información relevante en cards
7. ✅ Detalle muestra toda la información organizada
8. ✅ Estados tienen colores distintivos
9. ✅ Montos y fechas se formatean correctamente
10. ✅ Validaciones previenen datos inválidos

---

## ➡️ Próximos Pasos

**FASE 3**: Gestión Documental
- Upload/download de documentos
- Control de vencimientos
- Categorización de documentos

---

**✅ FASE 2 COMPLETADA**