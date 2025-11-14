# FASE 3: Gestión Documental 📁

**Duración estimada**: Sprint 5-6 (2-3 semanas)  
**Objetivo**: Implementar sistema completo de gestión documental con control de vencimientos

---

## 📋 Índice
1. [Objetivos de la Fase](#objetivos)
2. [Diseño de Base de Datos](#base-datos)
3. [Almacenamiento de Archivos](#almacenamiento)
4. [Implementación Backend](#implementacion-backend)
5. [Implementación Frontend](#implementacion-frontend)
6. [Control de Vencimientos](#vencimientos)
7. [Testing](#testing)
8. [Checklist](#checklist)

---

## 🎯 Objetivos de la Fase {#objetivos}

- ✅ Subir y descargar documentos
- ✅ Categorizar documentos por tipo
- ✅ Vincular documentos a licitaciones
- ✅ Control de vencimientos automático
- ✅ Historial de versiones de documentos
- ✅ Previsualización de documentos (PDF, imágenes)
- ✅ Búsqueda de documentos
- ✅ Alertas de vencimientos próximos
- ✅ Gestión de permisos por documento

---

## 🗄️ Diseño de Base de Datos {#base-datos}

```sql
-- Tabla de documentos
CREATE TABLE documentos (
    documento_id SERIAL PRIMARY KEY,
    
    -- Relaciones
    licitacion_id INTEGER REFERENCES licitaciones(licitacion_id),
    
    -- Información del archivo
    nombre_documento VARCHAR(255) NOT NULL,
    nombre_archivo_original VARCHAR(255) NOT NULL,
    nombre_archivo_almacenado VARCHAR(255) NOT NULL UNIQUE,
    ruta_archivo TEXT NOT NULL,
    extension VARCHAR(10) NOT NULL,
    tamanio_bytes BIGINT NOT NULL,
    mime_type VARCHAR(100),
    
    -- Categorización
    tipo_documento VARCHAR(100) NOT NULL,
    -- Tipos: oferta_tecnica, oferta_economica, pliego, garantia, 
    --        certificacion, contrato, adenda, otro
    
    categoria_documento VARCHAR(100),
    -- Categorías: ccss, hacienda, ins, municipal, bancario, legal, tecnico
    
    -- Control de versiones
    version INTEGER DEFAULT 1,
    documento_padre_id INTEGER REFERENCES documentos(documento_id),
    is_ultima_version BOOLEAN DEFAULT TRUE,
    
    -- Fechas de control
    fecha_emision DATE,
    fecha_vencimiento DATE,
    dias_alerta_vencimiento INTEGER DEFAULT 15,
    
    -- Estado
    estado_documento VARCHAR(50) DEFAULT 'activo',
    -- Estados: activo, vencido, reemplazado, eliminado
    
    -- Metadatos
    descripcion TEXT,
    tags TEXT[], -- Array de etiquetas para búsqueda
    hash_archivo VARCHAR(64), -- SHA256 para verificar integridad
    
    -- Auditoría
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    uploaded_by INTEGER REFERENCES users(user_id),
    
    -- Índices
    CONSTRAINT check_fecha_vencimiento CHECK (
        fecha_vencimiento IS NULL OR fecha_vencimiento >= fecha_emision
    )
);

-- Índices para optimización
CREATE INDEX idx_documentos_licitacion ON documentos(licitacion_id);
CREATE INDEX idx_documentos_tipo ON documentos(tipo_documento);
CREATE INDEX idx_documentos_vencimiento ON documentos(fecha_vencimiento);
CREATE INDEX idx_documentos_estado ON documentos(estado_documento);
CREATE INDEX idx_documentos_tags ON documentos USING GIN(tags);

-- Vista para documentos próximos a vencer
CREATE VIEW documentos_por_vencer AS
SELECT 
    d.*,
    l.numero_licitacion,
    l.nombre_licitacion,
    (d.fecha_vencimiento - CURRENT_DATE) as dias_restantes
FROM documentos d
LEFT JOIN licitaciones l ON d.licitacion_id = l.licitacion_id
WHERE d.fecha_vencimiento IS NOT NULL
  AND d.estado_documento = 'activo'
  AND d.is_active = TRUE
  AND d.fecha_vencimiento BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
ORDER BY d.fecha_vencimiento ASC;
```

---

## 📦 Almacenamiento de Archivos {#almacenamiento}

### Estrategia de Almacenamiento

**Estructura de directorios:**
```
uploads/
├── documentos/
│   ├── 2025/
│   │   ├── 01/
│   │   │   ├── licitacion_123/
│   │   │   │   ├── abc123_oferta_tecnica.pdf
│   │   │   │   └── def456_garantia.pdf
│   │   ├── 02/
│   │   └── ...
```

**Configuración:**

**app/core/config.py** (actualizar)
```python
class Settings(BaseSettings):
    # ... configuración existente ...
    
    # File storage
    UPLOAD_DIR: str = "uploads/documentos"
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10MB
    ALLOWED_EXTENSIONS: List[str] = [
        "pdf", "doc", "docx", "xls", "xlsx", 
        "jpg", "jpeg", "png", "zip"
    ]
```

---

## 💻 Implementación Backend {#implementacion-backend}

### 1. Modelo de Documento

**app/models/documento.py**
```python
from sqlalchemy import Column, Integer, String, Text, BigInteger, Date, Boolean, DateTime, ForeignKey, ARRAY
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base

class Documento(Base):
    __tablename__ = "documentos"
    
    documento_id = Column(Integer, primary_key=True, index=True)
    licitacion_id = Column(Integer, ForeignKey("licitaciones.licitacion_id"), index=True)
    
    # Información del archivo
    nombre_documento = Column(String(255), nullable=False)
    nombre_archivo_original = Column(String(255), nullable=False)
    nombre_archivo_almacenado = Column(String(255), nullable=False, unique=True)
    ruta_archivo = Column(Text, nullable=False)
    extension = Column(String(10), nullable=False)
    tamanio_bytes = Column(BigInteger, nullable=False)
    mime_type = Column(String(100))
    
    # Categorización
    tipo_documento = Column(String(100), nullable=False, index=True)
    categoria_documento = Column(String(100))
    
    # Control de versiones
    version = Column(Integer, default=1)
    documento_padre_id = Column(Integer, ForeignKey("documentos.documento_id"))
    is_ultima_version = Column(Boolean, default=True)
    
    # Fechas
    fecha_emision = Column(Date)
    fecha_vencimiento = Column(Date, index=True)
    dias_alerta_vencimiento = Column(Integer, default=15)
    
    # Estado
    estado_documento = Column(String(50), default="activo", index=True)
    
    # Metadatos
    descripcion = Column(Text)
    tags = Column(ARRAY(String))
    hash_archivo = Column(String(64))
    
    # Auditoría
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    uploaded_by = Column(Integer, ForeignKey("users.user_id"))
    
    # Relaciones
    licitacion = relationship("Licitacion", back_populates="documentos")
    documento_padre = relationship("Documento", remote_side=[documento_id])
```

**app/models/licitacion.py** (actualizar)
```python
# Agregar a la clase Licitacion:
documentos = relationship("Documento", back_populates="licitacion")
```

### 2. Schemas Pydantic

**app/schemas/documento.py**
```python
from pydantic import BaseModel, Field, validator
from typing import Optional, List
from datetime import date, datetime

class DocumentoBase(BaseModel):
    nombre_documento: str = Field(..., max_length=255)
    tipo_documento: str
    categoria_documento: Optional[str] = None
    fecha_emision: Optional[date] = None
    fecha_vencimiento: Optional[date] = None
    dias_alerta_vencimiento: int = Field(default=15, ge=1, le=90)
    descripcion: Optional[str] = None
    tags: Optional[List[str]] = None

    @validator('fecha_vencimiento')
    def validate_fecha_vencimiento(cls, v, values):
        if v and 'fecha_emision' in values and values['fecha_emision']:
            if v < values['fecha_emision']:
                raise ValueError('Fecha de vencimiento debe ser mayor a fecha de emisión')
        return v

class DocumentoCreate(DocumentoBase):
    licitacion_id: Optional[int] = None

class DocumentoUpdate(BaseModel):
    nombre_documento: Optional[str] = None
    tipo_documento: Optional[str] = None
    categoria_documento: Optional[str] = None
    fecha_emision: Optional[date] = None
    fecha_vencimiento: Optional[date] = None
    descripcion: Optional[str] = None
    tags: Optional[List[str]] = None

class DocumentoResponse(DocumentoBase):
    documento_id: int
    licitacion_id: Optional[int]
    nombre_archivo_original: str
    extension: str
    tamanio_bytes: int
    mime_type: Optional[str]
    version: int
    is_ultima_version: bool
    estado_documento: str
    created_at: datetime
    uploaded_by: int
    
    # Información de vencimiento
    dias_restantes: Optional[int] = None
    esta_vencido: bool = False
    esta_por_vencer: bool = False
    
    class Config:
        from_attributes = True

class DocumentoUploadResponse(BaseModel):
    documento_id: int
    nombre_documento: str
    nombre_archivo: str
    tamanio_bytes: int
    url_descarga: str
    message: str = "Documento subido exitosamente"
```

### 3. Utilidades de Archivos

**app/utils/file_utils.py**
```python
import os
import hashlib
import uuid
from pathlib import Path
from datetime import datetime
from typing import Optional
from fastapi import UploadFile, HTTPException

from app.core.config import settings

def validate_file_extension(filename: str) -> bool:
    """Validar que la extensión del archivo sea permitida"""
    ext = filename.split('.')[-1].lower()
    return ext in settings.ALLOWED_EXTENSIONS

def get_file_extension(filename: str) -> str:
    """Obtener extensión del archivo"""
    return filename.split('.')[-1].lower()

def generate_unique_filename(original_filename: str) -> str:
    """Generar nombre único para el archivo"""
    ext = get_file_extension(original_filename)
    unique_id = uuid.uuid4().hex
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    return f"{timestamp}_{unique_id}.{ext}"

def get_upload_path(licitacion_id: Optional[int] = None) -> Path:
    """Obtener ruta de subida organizada por fecha y licitación"""
    now = datetime.now()
    year = now.strftime("%Y")
    month = now.strftime("%m")
    
    if licitacion_id:
        path = Path(settings.UPLOAD_DIR) / year / month / f"licitacion_{licitacion_id}"
    else:
        path = Path(settings.UPLOAD_DIR) / year / month / "general"
    
    path.mkdir(parents=True, exist_ok=True)
    return path

def calculate_file_hash(file_path: str) -> str:
    """Calcular SHA256 hash del archivo"""
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

async def save_upload_file(
    upload_file: UploadFile,
    licitacion_id: Optional[int] = None
) -> tuple[str, str, int]:
    """
    Guardar archivo subido y retornar (ruta, nombre_almacenado, tamaño)
    """
    # Validar extensión
    if not validate_file_extension(upload_file.filename):
        raise HTTPException(
            status_code=400,
            detail=f"Extensión de archivo no permitida. Permitidas: {', '.join(settings.ALLOWED_EXTENSIONS)}"
        )
    
    # Generar nombre único
    unique_filename = generate_unique_filename(upload_file.filename)
    upload_path = get_upload_path(licitacion_id)
    file_path = upload_path / unique_filename
    
    # Guardar archivo
    content = await upload_file.read()
    file_size = len(content)
    
    # Validar tamaño
    if file_size > settings.MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"Archivo muy grande. Máximo: {settings.MAX_FILE_SIZE / (1024*1024)}MB"
        )
    
    with open(file_path, "wb") as f:
        f.write(content)
    
    return str(file_path), unique_filename, file_size

def delete_file(file_path: str) -> bool:
    """Eliminar archivo físico"""
    try:
        if os.path.exists(file_path):
            os.remove(file_path)
            return True
        return False
    except Exception:
        return False

def get_mime_type(filename: str) -> str:
    """Obtener MIME type basado en extensión"""
    ext = get_file_extension(filename)
    mime_types = {
        'pdf': 'application/pdf',
        'doc': 'application/msword',
        'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'xls': 'application/vnd.ms-excel',
        'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'zip': 'application/zip'
    }
    return mime_types.get(ext, 'application/octet-stream')
```

### 4. Service Layer

**app/services/documento_service.py**
```python
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from typing import List, Optional
from datetime import date, timedelta
from fastapi import UploadFile

from app.models.documento import Documento
from app.schemas.documento import DocumentoCreate, DocumentoUpdate, DocumentoResponse
from app.utils.file_utils import save_upload_file, calculate_file_hash, get_file_extension, get_mime_type, delete_file

class DocumentoService:
    
    @staticmethod
    async def upload_documento(
        db: Session,
        upload_file: UploadFile,
        documento_data: DocumentoCreate,
        user_id: int
    ) -> Documento:
        """Subir nuevo documento"""
        
        # Guardar archivo físico
        file_path, stored_filename, file_size = await save_upload_file(
            upload_file,
            documento_data.licitacion_id
        )
        
        # Calcular hash
        file_hash = calculate_file_hash(file_path)
        
        # Crear registro en BD
        db_documento = Documento(
            licitacion_id=documento_data.licitacion_id,
            nombre_documento=documento_data.nombre_documento,
            nombre_archivo_original=upload_file.filename,
            nombre_archivo_almacenado=stored_filename,
            ruta_archivo=file_path,
            extension=get_file_extension(upload_file.filename),
            tamanio_bytes=file_size,
            mime_type=get_mime_type(upload_file.filename),
            tipo_documento=documento_data.tipo_documento,
            categoria_documento=documento_data.categoria_documento,
            fecha_emision=documento_data.fecha_emision,
            fecha_vencimiento=documento_data.fecha_vencimiento,
            dias_alerta_vencimiento=documento_data.dias_alerta_vencimiento,
            descripcion=documento_data.descripcion,
            tags=documento_data.tags,
            hash_archivo=file_hash,
            uploaded_by=user_id
        )
        
        db.add(db_documento)
        db.commit()
        db.refresh(db_documento)
        
        # Actualizar estado si está vencido
        DocumentoService._update_documento_estado(db_documento)
        db.commit()
        
        return db_documento
    
    @staticmethod
    def get_documentos(
        db: Session,
        licitacion_id: Optional[int] = None,
        tipo_documento: Optional[str] = None,
        estado: Optional[str] = None,
        vencidos: Optional[bool] = None,
        por_vencer: Optional[bool] = None,
        skip: int = 0,
        limit: int = 100
    ) -> List[Documento]:
        """Obtener documentos con filtros"""
        
        query = db.query(Documento).filter(Documento.is_active == True)
        
        if licitacion_id:
            query = query.filter(Documento.licitacion_id == licitacion_id)
        
        if tipo_documento:
            query = query.filter(Documento.tipo_documento == tipo_documento)
        
        if estado:
            query = query.filter(Documento.estado_documento == estado)
        
        if vencidos:
            query = query.filter(
                and_(
                    Documento.fecha_vencimiento.isnot(None),
                    Documento.fecha_vencimiento < date.today()
                )
            )
        
        if por_vencer:
            fecha_limite = date.today() + timedelta(days=30)
            query = query.filter(
                and_(
                    Documento.fecha_vencimiento.isnot(None),
                    Documento.fecha_vencimiento.between(date.today(), fecha_limite)
                )
            )
        
        return query.order_by(Documento.created_at.desc()).offset(skip).limit(limit).all()
    
    @staticmethod
    def get_documento_by_id(db: Session, documento_id: int) -> Optional[Documento]:
        return db.query(Documento).filter(
            Documento.documento_id == documento_id,
            Documento.is_active == True
        ).first()
    
    @staticmethod
    def update_documento(
        db: Session,
        documento_id: int,
        documento_data: DocumentoUpdate
    ) -> Optional[Documento]:
        documento = DocumentoService.get_documento_by_id(db, documento_id)
        if not documento:
            return None
        
        update_data = documento_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(documento, field, value)
        
        # Actualizar estado
        DocumentoService._update_documento_estado(documento)
        
        db.commit()
        db.refresh(documento)
        return documento
    
    @staticmethod
    def delete_documento(db: Session, documento_id: int) -> bool:
        documento = DocumentoService.get_documento_by_id(db, documento_id)
        if not documento:
            return False
        
        # Soft delete
        documento.is_active = False
        documento.estado_documento = "eliminado"
        db.commit()
        
        # Opcional: eliminar archivo físico
        # delete_file(documento.ruta_archivo)
        
        return True
    
    @staticmethod
    def get_documentos_por_vencer(db: Session, dias: int = 30) -> List[Documento]:
        """Obtener documentos que vencen en los próximos X días"""
        fecha_limite = date.today() + timedelta(days=dias)
        
        return db.query(Documento).filter(
            and_(
                Documento.is_active == True,
                Documento.estado_documento == "activo",
                Documento.fecha_vencimiento.isnot(None),
                Documento.fecha_vencimiento.between(date.today(), fecha_limite)
            )
        ).order_by(Documento.fecha_vencimiento).all()
    
    @staticmethod
    def _update_documento_estado(documento: Documento):
        """Actualizar estado del documento según fecha de vencimiento"""
        if documento.fecha_vencimiento:
            if documento.fecha_vencimiento < date.today():
                documento.estado_documento = "vencido"
            elif documento.estado_documento == "vencido" and documento.fecha_vencimiento >= date.today():
                documento.estado_documento = "activo"
    
    @staticmethod
    def actualizar_estados_vencidos(db: Session) -> int:
        """Actualizar estados de documentos vencidos (ejecutar diariamente)"""
        documentos = db.query(Documento).filter(
            and_(
                Documento.is_active == True,
                Documento.estado_documento == "activo",
                Documento.fecha_vencimiento.isnot(None),
                Documento.fecha_vencimiento < date.today()
            )
        ).all()
        
        count = 0
        for doc in documentos:
            doc.estado_documento = "vencido"
            count += 1
        
        db.commit()
        return count
```

### 5. Endpoints de Documentos

**app/api/v1/endpoints/documentos.py**
```python
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List, Optional

from app.database import get_db
from app.models.user import User
from app.schemas.documento import (
    DocumentoCreate, DocumentoUpdate, DocumentoResponse, DocumentoUploadResponse
)
from app.services.documento_service import DocumentoService
from app.api.deps import get_current_user
import json

router = APIRouter()

@router.post("/upload", response_model=DocumentoUploadResponse, status_code=201)
async def upload_documento(
    file: UploadFile = File(...),
    nombre_documento: str = Form(...),
    tipo_documento: str = Form(...),
    licitacion_id: Optional[int] = Form(None),
    categoria_documento: Optional[str] = Form(None),
    fecha_emision: Optional[str] = Form(None),
    fecha_vencimiento: Optional[str] = Form(None),
    descripcion: Optional[str] = Form(None),
    tags: Optional[str] = Form(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Subir nuevo documento"""
    
    # Parsear tags si viene como JSON string
    tags_list = json.loads(tags) if tags else None
    
    documento_data = DocumentoCreate(
        nombre_documento=nombre_documento,
        tipo_documento=tipo_documento,
        licitacion_id=licitacion_id,
        categoria_documento=categoria_documento,
        fecha_emision=fecha_emision,
        fecha_vencimiento=fecha_vencimiento,
        descripcion=descripcion,
        tags=tags_list
    )
    
    documento = await DocumentoService.upload_documento(
        db=db,
        upload_file=file,
        documento_data=documento_data,
        user_id=current_user.user_id
    )
    
    return DocumentoUploadResponse(
        documento_id=documento.documento_id,
        nombre_documento=documento.nombre_documento,
        nombre_archivo=documento.nombre_archivo_original,
        tamanio_bytes=documento.tamanio_bytes,
        url_descarga=f"/api/v1/documentos/{documento.documento_id}/download"
    )

@router.get("/", response_model=List[DocumentoResponse])
def get_documentos(
    licitacion_id: Optional[int] = None,
    tipo_documento: Optional[str] = None,
    estado: Optional[str] = None,
    vencidos: Optional[bool] = None,
    por_vencer: Optional[bool] = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Listar documentos con filtros"""
    documentos = DocumentoService.get_documentos(
        db=db,
        licitacion_id=licitacion_id,
        tipo_documento=tipo_documento,
        estado=estado,
        vencidos=vencidos,
        por_vencer=por_vencer,
        skip=skip,
        limit=limit
    )
    
    # Agregar información de vencimiento
    from datetime import date
    result = []
    for doc in documentos:
        doc_dict = DocumentoResponse.from_orm(doc).model_dump()
        if doc.fecha_vencimiento:
            dias_restantes = (doc.fecha_vencimiento - date.today()).days
            doc_dict['dias_restantes'] = dias_restantes
            doc_dict['esta_vencido'] = dias_restantes < 0
            doc_dict['esta_por_vencer'] = 0 <= dias_restantes <= doc.dias_alerta_vencimiento
        result.append(DocumentoResponse(**doc_dict))
    
    return result

@router.get("/por-vencer")
def get_documentos_por_vencer(
    dias: int = Query(30, ge=1, le=90),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Obtener documentos que vencen próximamente"""
    documentos = DocumentoService.get_documentos_por_vencer(db, dias)
    
    from datetime import date
    result = []
    for doc in documentos:
        doc_dict = DocumentoResponse.from_orm(doc).model_dump()
        dias_restantes = (doc.fecha_vencimiento - date.today()).days
        doc_dict['dias_restantes'] = dias_restantes
        doc_dict['esta_por_vencer'] = True
        result.append(doc_dict)
    
    return result

@router.get("/{documento_id}", response_model=DocumentoResponse)
def get_documento(
    documento_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Obtener documento por ID"""
    documento = DocumentoService.get_documento_by_id(db, documento_id)
    if not documento:
        raise HTTPException(status_code=404, detail="Documento no encontrado")
    return documento

@router.get("/{documento_id}/download")
async def download_documento(
    documento_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Descargar archivo del documento"""
    documento = DocumentoService.get_documento_by_id(db, documento_id)
    if not documento:
        raise HTTPException(status_code=404, detail="Documento no encontrado")
    
    import os
    if not os.path.exists(documento.ruta_archivo):
        raise HTTPException(status_code=404, detail="Archivo no encontrado en el servidor")
    
    return FileResponse(
        path=documento.ruta_archivo,
        filename=documento.nombre_archivo_original,
        media_type=documento.mime_type
    )

@router.put("/{documento_id}", response_model=DocumentoResponse)
def update_documento(
    documento_id: int,
    documento_data: DocumentoUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Actualizar metadatos del documento"""
    documento = DocumentoService.update_documento(db, documento_id, documento_data)
    if not documento:
        raise HTTPException(status_code=404, detail="Documento no encontrado")
    return documento

@router.delete("/{documento_id}", status_code=204)
def delete_documento(
    documento_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Eliminar documento"""
    success = DocumentoService.delete_documento(db, documento_id)
    if not success:
        raise HTTPException(status_code=404, detail="Documento no encontrado")
    return None

@router.post("/actualizar-vencidos")
def actualizar_estados_vencidos(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["administrador"]))
):
    """Actualizar estados de documentos vencidos (tarea programada)"""
    count = DocumentoService.actualizar_estados_vencidos(db)
    return {"message": f"{count} documentos actualizados a estado 'vencido'"}
```

### 6. Actualizar Router Principal

**app/api/v1/__init__.py**
```python
from fastapi import APIRouter
from app.api.v1.endpoints import auth, users, licitaciones, clientes, documentos

router = APIRouter()

router.include_router(auth.router, prefix="/auth", tags=["Autenticación"])
router.include_router(users.router, prefix="/users", tags=["Usuarios"])
router.include_router(licitaciones.router, prefix="/licitaciones", tags=["Licitaciones"])
router.include_router(clientes.router, prefix="/clientes", tags=["Clientes"])
router.include_router(documentos.router, prefix="/documentos", tags=["Documentos"])
```

---

## 📱 Implementación Frontend {#implementacion-frontend}

### 1. Modelo de Documento

**lib/data/models/documento_model.dart**
```dart
import 'package:json_annotation/json_annotation.dart';

part 'documento_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class DocumentoModel {
  final int documentoId;
  final int? licitacionId;
  final String nombreDocumento;
  final String nombreArchivoOriginal;
  final String extension;
  final int tamanioBytes;
  final String? mimeType;
  final String tipoDocumento;
  final String? categoriaDocumento;
  final int version;
  final bool isUltimaVersion;
  final DateTime? fechaEmision;
  final DateTime? fechaVencimiento;
  final int diasAlertaVencimiento;
  final String estadoDocumento;
  final String? descripcion;
  final List<String>? tags;
  final DateTime createdAt;
  final int uploadedBy;
  
  // Campos calculados
  final int? diasRestantes;
  final bool estaVencido;
  final bool estaPorVencer;

  DocumentoModel({
    required this.documentoId,
    this.licitacionId,
    required this.nombreDocumento,
    required this.nombreArchivoOriginal,
    required this.extension,
    required this.tamanioBytes,
    this.mimeType,
    required this.tipoDocumento,
    this.categoriaDocumento,
    required this.version,
    required this.isUltimaVersion,
    this.fechaEmision,
    this.fechaVencimiento,
    required this.diasAlertaVencimiento,
    required this.estadoDocumento,
    this.descripcion,
    this.tags,
    required this.createdAt,
    required this.uploadedBy,
    this.diasRestantes,
    this.estaVencido = false,
    this.estaPorVencer = false,
  });

  factory DocumentoModel.fromJson(Map<String, dynamic> json) =>
      _$DocumentoModelFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentoModelToJson(this);
  
  String get tamanioFormatted {
    if (tamanioBytes < 1024) return '$tamanioBytes B';
    if (tamanioBytes < 1024 * 1024) {
      return '${(tamanioBytes / 1024).toStringAsFixed(2)} KB';
    }
    return '${(tamanioBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  
  Color getEstadoColor() {
    if (estaVencido) return Colors.red;
    if (estaPorVencer) return Colors.orange;
    return Colors.green;
  }
}
```

### 2. Repository de Documentos

**lib/data/repositories/documento_repository.dart**
```dart
import 'dart:io';
import 'package:dio/dio.dart';
import '../data_sources/api_client.dart';
import '../models/documento_model.dart';
import '../../core/config/api_config.dart';

class DocumentoRepository {
  final ApiClient _apiClient;

  DocumentoRepository(this._apiClient);

  Future<DocumentoModel> uploadDocumento({
    required File file,
    required String nombreDocumento,
    required String tipoDocumento,
    int? licitacionId,
    String? categoriaDocumento,
    DateTime? fechaEmision,
    DateTime? fechaVencimiento,
    String? descripcion,
    List<String>? tags,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        'nombre_documento': nombreDocumento,
        'tipo_documento': tipoDocumento,
        if (licitacionId != null) 'licitacion_id': licitacionId,
        if (categoriaDocumento != null) 'categoria_documento': categoriaDocumento,
        if (fechaEmision != null) 'fecha_emision': fechaEmision.toIso8601String().split('T')[0],
        if (fechaVencimiento != null) 'fecha_vencimiento': fechaVencimiento.toIso8601String().split('T')[0],
        if (descripcion != null) 'descripcion': descripcion,
        if (tags != null && tags.isNotEmpty) 'tags': jsonEncode(tags),
      });

      final response = await _apiClient.dio.post(
        '${ApiConfig.documentos}/upload',
        data: formData,
      );

      return DocumentoModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al subir documento: $e');
    }
  }

  Future<List<DocumentoModel>> getDocumentos({
    int? licitacionId,
    String? tipoDocumento,
    String? estado,
    bool? vencidos,
    bool? porVencer,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final queryParams = {
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      if (licitacionId != null) queryParams['licitacion_id'] = licitacionId.toString();
      if (tipoDocumento != null) queryParams['tipo_documento'] = tipoDocumento;
      if (estado != null) queryParams['estado'] = estado;
      if (vencidos != null) queryParams['vencidos'] = vencidos.toString();
      if (porVencer != null) queryParams['por_vencer'] = porVencer.toString();

      final response = await _apiClient.dio.get(
        ApiConfig.documentos,
        queryParameters: queryParams,
      );

      return (response.data as List)
          .map((json) => DocumentoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener documentos: $e');
    }
  }

  Future<List<DocumentoModel>> getDocumentosPorVencer({int dias = 30}) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConfig.documentos}/por-vencer',
        queryParameters: {'dias': dias},
      );

      return (response.data as List)
          .map((json) => DocumentoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener documentos por vencer: $e');
    }
  }

  Future<DocumentoModel> getDocumento(int documentoId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConfig.documentos}/$documentoId',
      );
      return DocumentoModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener documento: $e');
    }
  }

  Future<void> downloadDocumento(int documentoId, String savePath) async {
    try {
      await _apiClient.dio.download(
        '${ApiConfig.documentos}/$documentoId/download',
        savePath,
      );
    } catch (e) {
      throw Exception('Error al descargar documento: $e');
    }
  }

  Future<DocumentoModel> updateDocumento(
    int documentoId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConfig.documentos}/$documentoId',
        data: data,
      );
      return DocumentoModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar documento: $e');
    }
  }

  Future<void> deleteDocumento(int documentoId) async {
    try {
      await _apiClient.dio.delete(
        '${ApiConfig.documentos}/$documentoId',
      );
    } catch (e) {
      throw Exception('Error al eliminar documento: $e');
    }
  }
}
```

### 3. Pantalla de Lista de Documentos

**lib/presentation/screens/documentos/documentos_list_screen.dart**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DocumentosListScreen extends ConsumerStatefulWidget {
  final int? licitacionId;

  const DocumentosListScreen({Key? key, this.licitacionId}) : super(key: key);

  @override
  ConsumerState<DocumentosListScreen> createState() =>
      _DocumentosListScreenState();
}

class _DocumentosListScreenState extends ConsumerState<DocumentosListScreen> {
  String? _selectedTipo;
  String? _selectedEstado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.licitacionId != null
              ? 'Documentos de la Licitación'
              : 'Todos los Documentos',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Alertas de vencimientos
          _buildAlertasCard(),

          // Chips de filtros activos
          if (_selectedTipo != null || _selectedEstado != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedTipo != null)
                    Chip(
                      label: Text(_selectedTipo!),
                      onDeleted: () => setState(() => _selectedTipo = null),
                    ),
                  if (_selectedEstado != null)
                    Chip(
                      label: Text(_selectedEstado!),
                      onDeleted: () => setState(() => _selectedEstado = null),
                    ),
                ],
              ),
            ),

          // Lista de documentos
          Expanded(
            child: FutureBuilder(
              future: Future.delayed(Duration(seconds: 1)), // Simulación
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return _DocumentoCard(
                      onTap: () => _showDocumentoDetail(context, index),
                      onDownload: () => _downloadDocumento(index),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadDialog(context),
        icon: const Icon(Icons.upload_file),
        label: const Text('Subir Documento'),
      ),
    );
  }

  Widget _buildAlertasCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3 documentos por vencer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  Text(
                    'Revisa los documentos que vencen pronto',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                // Navegar a documentos por vencer
              },
              child: const Text('Ver'),
            ),
          ],
        ),
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
              value: _selectedTipo,
              decoration: const InputDecoration(labelText: 'Tipo de Documento'),
              items: const [
                DropdownMenuItem(
                    value: 'oferta_tecnica', child: Text('Oferta Técnica')),
                DropdownMenuItem(
                    value: 'oferta_economica', child: Text('Oferta Económica')),
                DropdownMenuItem(value: 'garantia', child: Text('Garantía')),
                DropdownMenuItem(
                    value: 'certificacion', child: Text('Certificación')),
                DropdownMenuItem(value: 'contrato', child: Text('Contrato')),
              ],
              onChanged: (value) {
                setState(() => _selectedTipo = value);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedEstado,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: const [
                DropdownMenuItem(value: 'activo', child: Text('Activo')),
                DropdownMenuItem(value: 'vencido', child: Text('Vencido')),
                DropdownMenuItem(
                    value: 'por_vencer', child: Text('Por Vencer')),
              ],
              onChanged: (value) {
                setState(() => _selectedEstado = value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedTipo = null;
                _selectedEstado = null;
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

  void _showUploadDialog(BuildContext context) {
    // Navegar a pantalla de upload
    Navigator.pushNamed(
      context,
      '/documento-upload',
      arguments: widget.licitacionId,
    );
  }

  void _showDocumentoDetail(BuildContext context, int documentoId) {
    Navigator.pushNamed(
      context,
      '/documento-detail',
      arguments: documentoId,
    );
  }

  void _downloadDocumento(int documentoId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Descargando documento...')),
    );
  }
}

class _DocumentoCard extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _DocumentoCard({
    required this.onTap,
    required this.onDownload,
  });

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
                  // Icono según tipo de archivo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Información del documento
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Certificación CCSS',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'certificacion_ccss_2025.pdf',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Estado
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '15 días',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // Información adicional
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Vence: 20/12/2025',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Icon(Icons.folder_open, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Certificación',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '2.4 MB',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Descargar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Icon(Icons.more_vert, size: 18),
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

### 4. Pantalla de Upload de Documentos

**lib/presentation/screens/documentos/documento_upload_screen.dart**
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class DocumentoUploadScreen extends StatefulWidget {
  final int? licitacionId;

  const DocumentoUploadScreen({Key? key, this.licitacionId}) : super(key: key);

  @override
  State<DocumentoUploadScreen> createState() => _DocumentoUploadScreenState();
}

class _DocumentoUploadScreenState extends State<DocumentoUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  File? _selectedFile;
  String? _selectedTipo;
  String? _selectedCategoria;
  DateTime? _fechaEmision;
  DateTime? _fechaVencimiento;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Documento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Selector de archivo
            _buildFileSelector(),
            const SizedBox(height: 24),

            // Nombre del documento
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Documento *',
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

            // Tipo de documento
            DropdownButtonFormField<String>(
              value: _selectedTipo,
              decoration: const InputDecoration(
                labelText: 'Tipo de Documento *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'oferta_tecnica', child: Text('Oferta Técnica')),
                DropdownMenuItem(
                    value: 'oferta_economica', child: Text('Oferta Económica')),
                DropdownMenuItem(value: 'pliego', child: Text('Pliego')),
                DropdownMenuItem(value: 'garantia', child: Text('Garantía')),
                DropdownMenuItem(
                    value: 'certificacion', child: Text('Certificación')),
                DropdownMenuItem(value: 'contrato', child: Text('Contrato')),
                DropdownMenuItem(value: 'adenda', child: Text('Adenda')),
                DropdownMenuItem(value: 'otro', child: Text('Otro')),
              ],
              onChanged: (value) => setState(() => _selectedTipo = value),
              validator: (value) => value == null ? 'Campo requerido' : null,
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
                DropdownMenuItem(value: 'ccss', child: Text('CCSS')),
                DropdownMenuItem(value: 'hacienda', child: Text('Hacienda')),
                DropdownMenuItem(value: 'ins', child: Text('INS')),
                DropdownMenuItem(value: 'municipal', child: Text('Municipal')),
                DropdownMenuItem(value: 'bancario', child: Text('Bancario')),
                DropdownMenuItem(value: 'legal', child: Text('Legal')),
                DropdownMenuItem(value: 'tecnico', child: Text('Técnico')),
              ],
              onChanged: (value) => setState(() => _selectedCategoria = value),
            ),
            const SizedBox(height: 16),

            // Fecha de emisión
            InkWell(
              onTap: () => _selectFechaEmision(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de Emisión',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _fechaEmision != null
                      ? '${_fechaEmision!.day}/${_fechaEmision!.month}/${_fechaEmision!.year}'
                      : 'Seleccionar fecha',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fecha de vencimiento
            InkWell(
              onTap: () => _selectFechaVencimiento(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de Vencimiento',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _fechaVencimiento != null
                      ? '${_fechaVencimiento!.day}/${_fechaVencimiento!.month}/${_fechaVencimiento!.year}'
                      : 'Seleccionar fecha',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
                    onPressed: _selectedFile == null || _isLoading
                        ? null
                        : _submitForm,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Subir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelector() {
    return Card(
      child: InkWell(
        onTap: _pickFile,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              if (_selectedFile == null) ...[
                Icon(Icons.upload_file, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Seleccionar archivo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Formatos permitidos: PDF, DOC, XLS, IMG, ZIP',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ] else ...[
                Icon(Icons.insert_drive_file, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  _selectedFile!.path.split('/').last,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedFile = null),
                  icon: const Icon(Icons.close),
                  label: const Text('Quitar archivo'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png', 'zip'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _selectFechaEmision(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaEmision ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _fechaEmision = picked);
    }
  }

  Future<void> _selectFechaVencimiento(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaVencimiento ?? DateTime.now(),
      firstDate: _fechaEmision ?? DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _fechaVencimiento = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) return;

    setState(() => _isLoading = true);

    try {
      // Aquí integrarías con tu repository
      await Future.delayed(const Duration(seconds: 2)); // Simulación

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento subido exitosamente')),
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

## ⏰ Control de Vencimientos {#vencimientos}

### Worker para Verificar Vencimientos

**app/workers/documento_worker.py**
```python
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.services.documento_service import DocumentoService
import logging

logger = logging.getLogger(__name__)

def verificar_vencimientos():
    """Tarea programada para actualizar estados de documentos vencidos"""
    db: Session = SessionLocal()
    try:
        count = DocumentoService.actualizar_estados_vencidos(db)
        logger.info(f"Documentos actualizados a estado 'vencido': {count}")
    except Exception as e:
        logger.error(f"Error al verificar vencimientos: {e}")
    finally:
        db.close()

def init_scheduler():
    """Inicializar scheduler de tareas programadas"""
    scheduler = BackgroundScheduler()
    
    # Ejecutar todos los días a las 00:01
    scheduler.add_job(
        verificar_vencimientos,
        trigger=CronTrigger(hour=0, minute=1),
        id='verificar_vencimientos',
        name='Verificar documentos vencidos',
        replace_existing=True
    )
    
    scheduler.start()
    logger.info("Scheduler iniciado - Verificación de vencimientos programada")
    
    return scheduler
```

**app/main.py** (actualizar)
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.v1 import router as api_router
from app.database import engine, Base
from app.workers.documento_worker import init_scheduler

# Crear tablas
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_PREFIX}/openapi.json"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Iniciar scheduler
scheduler = init_scheduler()

# Router principal
app.include_router(api_router, prefix=settings.API_V1_PREFIX)

@app.on_event("shutdown")
def shutdown_event():
    scheduler.shutdown()

@app.get("/")
def root():
    return {
        "message": "Sistema de Gestión de Licitaciones API",
        "version": settings.VERSION,
        "docs": f"{settings.API_V1_PREFIX}/docs"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}
```

**requirements.txt** (agregar)
```txt
APScheduler==3.10.4
```

---

## 🧪 Testing {#testing}

### Backend Tests

**tests/test_documentos.py**
```python
import pytest
from fastapi.testclient import TestClient
from app.main import app
import io

client = TestClient(app)

def test_upload_documento(auth_token):
    files = {
        'file': ('test.pdf', io.BytesIO(b'fake pdf content'), 'application/pdf')
    }
    data = {
        'nombre_documento': 'Documento de Prueba',
        'tipo_documento': 'certificacion',
    }
    
    response = client.post(
        "/api/v1/documentos/upload",
        headers={"Authorization": f"Bearer {auth_token}"},
        files=files,
        data=data
    )
    assert response.status_code == 201
    assert 'documento_id' in response.json()

def test_get_documentos(auth_token):
    response = client.get(
        "/api/v1/documentos/",
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_filter_documentos_por_vencer(auth_token):
    response = client.get(
        "/api/v1/documentos/por-vencer?dias=30",
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert response.status_code == 200

def test_download_documento(auth_token, documento_id):
    response = client.get(
        f"/api/v1/documentos/{documento_id}/download",
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert response.status_code == 200
```

---

## ✅ Checklist de Completitud {#checklist}

### Backend
- [ ] Modelo Documento creado con todas las relaciones
- [ ] Migraciones aplicadas correctamente
- [ ] Sistema de almacenamiento de archivos configurado
- [ ] Validación de extensiones permitidas
- [ ] Validación de tamaño máximo de archivos
- [ ] Generación de nombres únicos de archivos
- [ ] Cálculo de hash SHA256 para integridad
- [ ] Upload de documentos funcionando
- [ ] Download de documentos funcionando
- [ ] Filtros por tipo, estado, vencimiento
- [ ] Vista de documentos por vencer
- [ ] Actualización automática de estados vencidos
- [ ] Scheduler configurado y funcionando
- [ ] Soft delete implementado
- [ ] Control de versiones de documentos
- [ ] Tests unitarios pasando

### Frontend
- [ ] Modelo DocumentoModel creado
- [ ] Repository implementado con multipart/form-data
- [ ] File picker funcionando
- [ ] Validación de tipos de archivo en cliente
- [ ] Pantalla de lista de documentos
- [ ] Filtros por tipo y estado
- [ ] Card de alertas de vencimientos
- [ ] Pantalla de upload con formulario completo
- [ ] Previsualización de archivo seleccionado
- [ ] Date pickers para fechas
- [ ] Download de documentos
- [ ] Indicadores visuales de estado (colores)
- [ ] Formato de tamaño de archivo
- [ ] Manejo de errores en upload

### Integración
- [ ] Upload completo funcionando (backend + frontend)
- [ ] Download funcionando correctamente
- [ ] Archivos se guardan en estructura correcta
- [ ] Listado muestra documentos reales
- [ ] Filtros funcionan correctamente
- [ ] Alertas de vencimiento actualizadas
- [ ] Estados se actualizan automáticamente
- [ ] Integración con licitaciones

---

## 🚀 Comandos de Ejecución

### Crear directorios de upload
```bash
mkdir -p uploads/documentos
chmod 755 uploads/documentos
```

### Instalar dependencias adicionales
```bash
pip install APScheduler
flutter pub add file_picker
flutter pub add path_provider
```

---

## 📊 Criterios de Aceptación

1. ✅ Usuario puede subir documentos (PDF, DOC, XLS, IMG)
2. ✅ Documentos se categorizan por tipo
3. ✅ Documentos tienen fechas de vencimiento opcionales
4. ✅ Sistema alerta sobre documentos próximos a vencer
5. ✅ Usuario puede descargar documentos
6. ✅ Usuario puede filtrar documentos por múltiples criterios
7. ✅ Estados se actualizan automáticamente (vencido/activo)
8. ✅ Archivos se almacenan con nombres únicos
9. ✅ Sistema valida extensiones y tamaños
10. ✅ Dashboard muestra alertas de vencimientos

---

## 🐛 Troubleshooting

### Error: "File too large"
```python
# Aumentar límite en config.py
MAX_FILE_SIZE: int = 20 * 1024 * 1024  # 20MB
```

### Error: "Permission denied" al guardar archivos
```bash
# Dar permisos al directorio
chmod -R 755 uploads/
```

### Flutter: Error al seleccionar archivo en web
```yaml
# Agregar en pubspec.yaml
file_picker: ^5.5.0
```

---

## ➡️ Próximos Pasos

**FASE 4**: Ampliaciones y Prórrogas
- Registro de cambios en contratos
- Historial de modificaciones
- Documentación de ampliaciones

---

**✅ FASE 3 COMPLETADA**