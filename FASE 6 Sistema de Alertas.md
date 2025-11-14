# FASE 6: Sistema de Alertas 🔔

**Duración estimada**: Sprint 9-10 (2 semanas)  
**Objetivo**: Implementar sistema completo de notificaciones y alertas automáticas

---

## 📋 Índice
1. [Objetivos de la Fase](#objetivos)
2. [Diseño de Base de Datos](#base-datos)
3. [Implementación Backend](#implementacion-backend)
4. [Implementación Frontend](#implementacion-frontend)
5. [Workers y Tareas Programadas](#workers)
6. [Testing](#testing)
7. [Checklist](#checklist)

---

## 🎯 Objetivos de la Fase {#objetivos}

- ✅ Motor de generación de alertas automáticas
- ✅ Alertas de documentos vencidos/por vencer
- ✅ Alertas de contratos próximos a finalizar
- ✅ Alertas de garantías por vencer
- ✅ Alertas de seguimientos pendientes
- ✅ Dashboard de alertas con prioridades
- ✅ Notificaciones por email (opcional)
- ✅ Configuración personalizada por usuario
- ✅ Marcar alertas como leídas/resueltas
- ✅ Historial de alertas

---

## 🗄️ Diseño de Base de Datos {#base-datos}

```sql
-- Tabla principal de alertas
CREATE TABLE alertas (
    alerta_id SERIAL PRIMARY KEY,
    
    -- Tipo de alerta
    tipo_alerta VARCHAR(50) NOT NULL,
    -- Tipos: documento_vencido, documento_por_vencer, contrato_proximo_fin,
    --        garantia_vencida, garantia_por_vencer, seguimiento_pendiente,
    --        licitacion_proxima, ampliacion_pendiente, interaccion_programada
    
    -- Referencias (pueden ser NULL dependiendo del tipo)
    licitacion_id INTEGER REFERENCES licitaciones(licitacion_id),
    documento_id INTEGER REFERENCES documentos(documento_id),
    ampliacion_id INTEGER REFERENCES ampliaciones(ampliacion_id),
    seguimiento_id INTEGER REFERENCES seguimientos(seguimiento_id),
    cliente_id INTEGER REFERENCES clientes(cliente_id),
    user_id INTEGER REFERENCES users(user_id), -- Usuario destinatario (NULL = todos)
    
    -- Contenido de la alerta
    titulo VARCHAR(255) NOT NULL,
    mensaje TEXT NOT NULL,
    
    -- Prioridad
    nivel_prioridad VARCHAR(20) DEFAULT 'media',
    -- Niveles: baja, media, alta, critica
    
    -- Estado
    estado_alerta VARCHAR(50) DEFAULT 'activa',
    -- Estados: activa, leida, archivada, resuelta, descartada
    
    -- Fechas
    fecha_alerta TIMESTAMP NOT NULL,
    fecha_leida TIMESTAMP,
    fecha_resuelta TIMESTAMP,
    fecha_descartada TIMESTAMP,
    
    -- Acciones
    requiere_accion BOOLEAN DEFAULT FALSE,
    url_accion TEXT, -- URL para navegar al detalle
    accion_sugerida VARCHAR(255),
    
    -- Notificaciones
    enviada_email BOOLEAN DEFAULT FALSE,
    fecha_envio_email TIMESTAMP,
    email_destinatario VARCHAR(255),
    
    -- Recurrencia (para alertas que se repiten)
    es_recurrente BOOLEAN DEFAULT FALSE,
    frecuencia_dias INTEGER,
    ultima_generacion TIMESTAMP,
    
    -- Observaciones
    notas_usuario TEXT,
    
    -- Auditoría
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER REFERENCES users(user_id)
);

-- Tabla de configuración de alertas por usuario
CREATE TABLE configuracion_alertas (
    config_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) NOT NULL UNIQUE,
    
    -- Activación por tipo de alerta
    alertas_documentos_vencidos BOOLEAN DEFAULT TRUE,
    dias_alerta_documentos INTEGER DEFAULT 15,
    
    alertas_contratos_proximos BOOLEAN DEFAULT TRUE,
    dias_alerta_contratos INTEGER DEFAULT 30,
    
    alertas_garantias BOOLEAN DEFAULT TRUE,
    dias_alerta_garantias INTEGER DEFAULT 15,
    
    alertas_seguimientos BOOLEAN DEFAULT TRUE,
    dias_alerta_seguimientos INTEGER DEFAULT 1, -- 1 día antes
    
    alertas_licitaciones BOOLEAN DEFAULT TRUE,
    alertas_ampliaciones BOOLEAN DEFAULT TRUE,
    
    -- Canales de notificación
    notificar_email BOOLEAN DEFAULT TRUE,
    notificar_push BOOLEAN DEFAULT FALSE,
    notificar_sms BOOLEAN DEFAULT FALSE,
    
    -- Horarios (para no molestar fuera de horario)
    horario_inicio TIME DEFAULT '08:00:00',
    horario_fin TIME DEFAULT '18:00:00',
    notificar_fines_semana BOOLEAN DEFAULT FALSE,
    
    -- Frecuencia de resumen
    enviar_resumen_diario BOOLEAN DEFAULT TRUE,
    hora_resumen_diario TIME DEFAULT '08:00:00',
    
    -- Actualización
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de historial de notificaciones enviadas
CREATE TABLE historial_notificaciones (
    notificacion_id SERIAL PRIMARY KEY,
    alerta_id INTEGER REFERENCES alertas(alerta_id) NOT NULL,
    user_id INTEGER REFERENCES users(user_id) NOT NULL,
    
    canal VARCHAR(50) NOT NULL, -- email, push, sms
    destinatario VARCHAR(255) NOT NULL,
    
    asunto VARCHAR(255),
    contenido TEXT,
    
    estado_envio VARCHAR(50) DEFAULT 'pendiente',
    -- Estados: pendiente, enviado, fallido, rebotado
    
    fecha_envio TIMESTAMP,
    fecha_lectura TIMESTAMP,
    
    error_mensaje TEXT,
    intentos INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para optimización
CREATE INDEX idx_alertas_user ON alertas(user_id);
CREATE INDEX idx_alertas_estado ON alertas(estado_alerta);
CREATE INDEX idx_alertas_tipo ON alertas(tipo_alerta);
CREATE INDEX idx_alertas_fecha ON alertas(fecha_alerta DESC);
CREATE INDEX idx_alertas_prioridad ON alertas(nivel_prioridad);
CREATE INDEX idx_config_alertas_user ON configuracion_alertas(user_id);
CREATE INDEX idx_historial_notif_alerta ON historial_notificaciones(alerta_id);
CREATE INDEX idx_historial_notif_user ON historial_notificaciones(user_id);

-- Vista para alertas activas agrupadas
CREATE VIEW alertas_resumen AS
SELECT 
    tipo_alerta,
    nivel_prioridad,
    COUNT(*) as total,
    COUNT(CASE WHEN estado_alerta = 'activa' THEN 1 END) as activas,
    COUNT(CASE WHEN estado_alerta = 'leida' THEN 1 END) as leidas,
    COUNT(CASE WHEN requiere_accion = TRUE THEN 1 END) as requieren_accion
FROM alertas
WHERE estado_alerta IN ('activa', 'leida')
GROUP BY tipo_alerta, nivel_prioridad;
```

---

## 💻 Implementación Backend {#implementacion-backend}

### 1. Modelos

**app/models/alerta.py**
```python
from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, Time, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base

class Alerta(Base):
    __tablename__ = "alertas"
    
    alerta_id = Column(Integer, primary_key=True, index=True)
    
    tipo_alerta = Column(String(50), nullable=False, index=True)
    
    # Referencias
    licitacion_id = Column(Integer, ForeignKey("licitaciones.licitacion_id"))
    documento_id = Column(Integer, ForeignKey("documentos.documento_id"))
    ampliacion_id = Column(Integer, ForeignKey("ampliaciones.ampliacion_id"))
    seguimiento_id = Column(Integer, ForeignKey("seguimientos.seguimiento_id"))
    cliente_id = Column(Integer, ForeignKey("clientes.cliente_id"))
    user_id = Column(Integer, ForeignKey("users.user_id"), index=True)
    
    # Contenido
    titulo = Column(String(255), nullable=False)
    mensaje = Column(Text, nullable=False)
    
    # Prioridad y estado
    nivel_prioridad = Column(String(20), default='media', index=True)
    estado_alerta = Column(String(50), default='activa', index=True)
    
    # Fechas
    fecha_alerta = Column(DateTime, nullable=False, index=True)
    fecha_leida = Column(DateTime)
    fecha_resuelta = Column(DateTime)
    fecha_descartada = Column(DateTime)
    
    # Acciones
    requiere_accion = Column(Boolean, default=False)
    url_accion = Column(Text)
    accion_sugerida = Column(String(255))
    
    # Notificaciones
    enviada_email = Column(Boolean, default=False)
    fecha_envio_email = Column(DateTime)
    email_destinatario = Column(String(255))
    
    # Recurrencia
    es_recurrente = Column(Boolean, default=False)
    frecuencia_dias = Column(Integer)
    ultima_generacion = Column(DateTime)
    
    # Notas
    notas_usuario = Column(Text)
    
    # Auditoría
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    created_by = Column(Integer, ForeignKey("users.user_id"))
    
    # Relaciones
    usuario = relationship("User", foreign_keys=[user_id])
    licitacion = relationship("Licitacion")
    documento = relationship("Documento")

class ConfiguracionAlertas(Base):
    __tablename__ = "configuracion_alertas"
    
    config_id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False, unique=True)
    
    # Activación por tipo
    alertas_documentos_vencidos = Column(Boolean, default=True)
    dias_alerta_documentos = Column(Integer, default=15)
    
    alertas_contratos_proximos = Column(Boolean, default=True)
    dias_alerta_contratos = Column(Integer, default=30)
    
    alertas_garantias = Column(Boolean, default=True)
    dias_alerta_garantias = Column(Integer, default=15)
    
    alertas_seguimientos = Column(Boolean, default=True)
    dias_alerta_seguimientos = Column(Integer, default=1)
    
    alertas_licitaciones = Column(Boolean, default=True)
    alertas_ampliaciones = Column(Boolean, default=True)
    
    # Canales
    notificar_email = Column(Boolean, default=True)
    notificar_push = Column(Boolean, default=False)
    notificar_sms = Column(Boolean, default=False)
    
    # Horarios
    horario_inicio = Column(Time, default='08:00:00')
    horario_fin = Column(Time, default='18:00:00')
    notificar_fines_semana = Column(Boolean, default=False)
    
    # Resumen
    enviar_resumen_diario = Column(Boolean, default=True)
    hora_resumen_diario = Column(Time, default='08:00:00')
    
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relaciones
    usuario = relationship("User")

class HistorialNotificacion(Base):
    __tablename__ = "historial_notificaciones"
    
    notificacion_id = Column(Integer, primary_key=True)
    alerta_id = Column(Integer, ForeignKey("alertas.alerta_id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    
    canal = Column(String(50), nullable=False)
    destinatario = Column(String(255), nullable=False)
    
    asunto = Column(String(255))
    contenido = Column(Text)
    
    estado_envio = Column(String(50), default='pendiente')
    fecha_envio = Column(DateTime)
    fecha_lectura = Column(DateTime)
    
    error_mensaje = Column(Text)
    intentos = Column(Integer, default=0)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relaciones
    alerta = relationship("Alerta")
    usuario = relationship("User")
```

### 2. Schemas

**app/schemas/alerta.py**
```python
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class AlertaBase(BaseModel):
    tipo_alerta: str
    titulo: str = Field(..., max_length=255)
    mensaje: str
    nivel_prioridad: str = Field(default='media')
    requiere_accion: bool = False
    url_accion: Optional[str] = None
    accion_sugerida: Optional[str] = None

class AlertaCreate(AlertaBase):
    licitacion_id: Optional[int] = None
    documento_id: Optional[int] = None
    ampliacion_id: Optional[int] = None
    seguimiento_id: Optional[int] = None
    cliente_id: Optional[int] = None
    user_id: Optional[int] = None

class AlertaUpdate(BaseModel):
    estado_alerta: Optional[str] = None
    notas_usuario: Optional[str] = None

class AlertaResponse(AlertaBase):
    alerta_id: int
    licitacion_id: Optional[int]
    documento_id: Optional[int]
    user_id: Optional[int]
    estado_alerta: str
    fecha_alerta: datetime
    fecha_leida: Optional[datetime]
    fecha_resuelta: Optional[datetime]
    enviada_email: bool
    created_at: datetime
    
    # Información adicional
    dias_restantes: Optional[int] = None
    numero_licitacion: Optional[str] = None
    nombre_documento: Optional[str] = None
    
    class Config:
        from_attributes = True

class ConfiguracionAlertasUpdate(BaseModel):
    alertas_documentos_vencidos: Optional[bool] = None
    dias_alerta_documentos: Optional[int] = None
    alertas_contratos_proximos: Optional[bool] = None
    dias_alerta_contratos: Optional[int] = None
    alertas_garantias: Optional[bool] = None
    dias_alerta_garantias: Optional[int] = None
    notificar_email: Optional[bool] = None
    enviar_resumen_diario: Optional[bool] = None

class ConfiguracionAlertasResponse(BaseModel):
    config_id: int
    user_id: int
    alertas_documentos_vencidos: bool
    dias_alerta_documentos: int
    alertas_contratos_proximos: bool
    dias_alerta_contratos: int
    alertas_garantias: bool
    dias_alerta_garantias: int
    notificar_email: bool
    enviar_resumen_diario: bool
    
    class Config:
        from_attributes = True
```

### 3. Service Layer

**app/services/alerta_service.py**
```python
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func
from typing import List, Optional
from datetime import date, datetime, timedelta

from app.models.alerta import Alerta, ConfiguracionAlertas
from app.models.documento import Documento
from app.models.licitacion import Licitacion
from app.models.seguimiento import Seguimiento
from app.schemas.alerta import AlertaCreate

class AlertaService:
    
    @staticmethod
    def generar_alertas_documentos_vencidos(db: Session):
        """Generar alertas para documentos próximos a vencer"""
        
        # Obtener configuraciones de usuarios
        configs = db.query(ConfiguracionAlertas).filter(
            ConfiguracionAlertas.alertas_documentos_vencidos == True
        ).all()
        
        for config in configs:
            dias_alerta = config.dias_alerta_documentos
            fecha_limite = date.today() + timedelta(days=dias_alerta)
            
            # Buscar documentos que vencen
            documentos = db.query(Documento).filter(
                Documento.fecha_vencimiento.between(date.today(), fecha_limite),
                Documento.estado_documento == 'activo',
                Documento.is_active == True
            ).all()
            
            for doc in documentos:
                # Verificar si ya existe alerta activa para este documento
                alerta_existente = db.query(Alerta).filter(
                    Alerta.documento_id == doc.documento_id,
                    Alerta.tipo_alerta == 'documento_por_vencer',
                    Alerta.estado_alerta == 'activa',
                    Alerta.user_id == config.user_id
                ).first()
                
                if not alerta_existente:
                    dias_restantes = (doc.fecha_vencimiento - date.today()).days
                    nivel = AlertaService._calcular_nivel_prioridad(dias_restantes, dias_alerta)
                    
                    alerta = Alerta(
                        tipo_alerta='documento_por_vencer',
                        documento_id=doc.documento_id,
                        licitacion_id=doc.licitacion_id,
                        user_id=config.user_id,
                        titulo=f'Documento vence en {dias_restantes} días',
                        mensaje=f'El documento "{doc.nombre_documento}" vencerá el {doc.fecha_vencimiento.strftime("%d/%m/%Y")}',
                        nivel_prioridad=nivel,
                        fecha_alerta=datetime.now(),
                        requiere_accion=True,
                        url_accion=f'/documentos/{doc.documento_id}',
                        accion_sugerida='Renovar documento antes del vencimiento'
                    )
                    db.add(alerta)
        
        db.commit()
    
    @staticmethod
    def generar_alertas_contratos_proximos(db: Session):
        """Generar alertas para contratos próximos a finalizar"""
        
        configs = db.query(ConfiguracionAlertas).filter(
            ConfiguracionAlertas.alertas_contratos_proximos == True
        ).all()
        
        for config in configs:
            dias_alerta = config.dias_alerta_contratos
            fecha_limite = date.today() + timedelta(days=dias_alerta)
            
            licitaciones = db.query(Licitacion).filter(
                Licitacion.fecha_fin_contrato.between(date.today(), fecha_limite),
                Licitacion.estado_licitacion == 'en_ejecucion',
                Licitacion.is_active == True
            ).all()
            
            for lic in licitaciones:
                alerta_existente = db.query(Alerta).filter(
                    Alerta.licitacion_id == lic.licitacion_id,
                    Alerta.tipo_alerta == 'contrato_proximo_fin',
                    Alerta.estado_alerta == 'activa',
                    Alerta.user_id == config.user_id
                ).first()
                
                if not alerta_existente:
                    dias_restantes = (lic.fecha_fin_contrato - date.today()).days
                    nivel = AlertaService._calcular_nivel_prioridad(dias_restantes, dias_alerta)
                    
                    alerta = Alerta(
                        tipo_alerta='contrato_proximo_fin',
                        licitacion_id=lic.licitacion_id,
                        cliente_id=lic.cliente_id,
                        user_id=config.user_id,
                        titulo=f'Contrato finaliza en {dias_restantes} días',
                        mensaje=f'La licitación "{lic.nombre_licitacion}" ({lic.numero_licitacion}) finaliza el {lic.fecha_fin_contrato.strftime("%d/%m/%Y")}',
                        nivel_prioridad=nivel,
                        fecha_alerta=datetime.now(),
                        requiere_accion=True,
                        url_accion=f'/licitaciones/{lic.licitacion_id}',
                        accion_sugerida='Evaluar renovación o cierre del contrato'
                    )
                    db.add(alerta)
        
        db.commit()
    
    @staticmethod
    def generar_alertas_seguimientos(db: Session):
        """Generar alertas para seguimientos programados"""
        
        configs = db.query(ConfiguracionAlertas).filter(
            ConfiguracionAlertas.alertas_seguimientos == True
        ).all()
        
        for config in configs:
            dias_alerta = config.dias_alerta_seguimientos
            fecha_alerta = date.today() + timedelta(days=dias_alerta)
            
            seguimientos = db.query(Seguimiento).filter(
                Seguimiento.fecha_programada == fecha_alerta,
                Seguimiento.estado_seguimiento == 'pendiente',
                or_(
                    Seguimiento.responsable_id == config.user_id,
                    Seguimiento.responsable_id.is_(None)
                )
            ).all()
            
            for seg in seguimientos:
                alerta_existente = db.query(Alerta).filter(
                    Alerta.seguimiento_id == seg.seguimiento_id,
                    Alerta.estado_alerta == 'activa',
                    Alerta.user_id == config.user_id
                ).first()
                
                if not alerta_existente:
                    alerta = Alerta(
                        tipo_alerta='seguimiento_pendiente',
                        seguimiento_id=seg.seguimiento_id,
                        cliente_id=seg.cliente_id,
                        user_id=config.user_id,
                        titulo=f'Seguimiento programado para mañana',
                        mensaje=f'Tienes un seguimiento pendiente: {seg.titulo}',
                        nivel_prioridad='media',
                        fecha_alerta=datetime.now(),
                        requiere_accion=True,
                        url_accion=f'/seguimientos/{seg.seguimiento_id}',
                        accion_sugerida='Completar seguimiento'
                    )
                    db.add(alerta)
        
        db.commit()
    
    @staticmethod
    def _calcular_nivel_prioridad(dias_restantes: int, dias_alerta_max: int) -> str:
        """Calcular nivel de prioridad según días restantes"""
        porcentaje = (dias_restantes / dias_alerta_max) * 100
        
        if porcentaje <= 25:
            return 'critica'
        elif porcentaje <= 50:
            return 'alta'
        elif porcentaje <= 75:
            return 'media'
        else:
            return 'baja'
    
    @staticmethod
    def get_alertas_activas(
        db: Session,
        user_id: Optional[int] = None,
        tipo_alerta: Optional[str] = None,
        nivel_prioridad: Optional[str] = None,
        skip: int = 0,
        limit: int = 100
    ) -> List[Alerta]:
        """Obtener alertas activas con filtros"""
        
        query = db.query(Alerta).filter(
            Alerta.estado_alerta.in_(['activa', 'leida'])
        )
        
        if user_id:
            query = query.filter(or_(
                Alerta.user_id == user_id,
                Alerta.user_id.is_(None)  # Alertas globales
            ))
        
        if tipo_alerta:
            query = query.filter(Alerta.tipo_alerta == tipo_alerta)
        
        if nivel_prioridad:
            query = query.filter(Alerta.nivel_prioridad == nivel_prioridad)
        
        return query.order_by(
            Alerta.nivel_prioridad.desc(),
            Alerta.fecha_alerta.desc()
        ).offset(skip).limit(limit).all()
    
    @staticmethod
    def marcar_como_leida(db: Session, alerta_id: int, user_id: int) -> Optional[Alerta]:
        """Marcar alerta como leída"""
        alerta = db.query(Alerta).filter(
            Alerta.alerta_id == alerta_id,
            or_(Alerta.user_id == user_id, Alerta.user_id.is_(None))
        ).first()
        
        if alerta and alerta.estado_alerta == 'activa':
            alerta.estado_alerta = 'leida'
            alerta.fecha_leida = datetime.now()
            db.commit()
            db.refresh(alerta)
        
        return alerta
    
    @staticmethod
    def marcar_como_resuelta(db: Session, alerta_id: int, user_id: int) -> Optional[Alerta]:
        """Marcar alerta como resuelta"""
        alerta = db.query(Alerta).filter(
            Alerta.alerta_id == alerta_id,
            or_(Alerta.user_id == user_id, Alerta.user_id.is_(None))
        ).first()
        
        if alerta:
            alerta.estado_alerta = 'resuelta'
            alerta.fecha_resuelta = datetime.now()
            db.commit()
            db.refresh(alerta)
        
        return alerta
    
    @staticmethod
    def get_resumen_alertas(db: Session, user_id: Optional[int] = None) -> dict:
        """Obtener resumen de alertas por prioridad"""
        
        query = db.query(
            Alerta.nivel_prioridad,
            func.count(Alerta.alerta_id).label('total')
        ).filter(
            Alerta.estado_alerta == 'activa'
        )
        
        if user_id:
            query = query.filter(or_(
                Alerta.user_id == user_id,
                Alerta.user_id.is_(None)
            ))
        
        result = query.group_by(Alerta.nivel_prioridad).all()
        
        resumen = {
            'critica': 0,
            'alta': 0,
            'media': 0,
            'baja': 0,
            'total': 0
        }
        
        for row in result:
            resumen[row[0]] = row[1]
            resumen['total'] += row[1]
        
        return resumen
    
    @staticmethod
    def get_or_create_configuracion(db: Session, user_id: int) -> ConfiguracionAlertas:
        """Obtener o crear configuración de alertas del usuario"""
        
        config = db.query(ConfiguracionAlertas).filter(
            ConfiguracionAlertas.user_id == user_id
        ).first()
        
        if not config:
            config = ConfiguracionAlertas(user_id=user_id)
            db.add(config)
            db.commit()
            db.refresh(config)
        
        return config
```

### 4. Endpoints

**app/api/v1/endpoints/alertas.py**
```python
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from app.database import get_db
from app.models.user import User
from app.schemas.alerta import (
    AlertaResponse, AlertaUpdate,
    ConfiguracionAlertasUpdate, ConfiguracionAlertasResponse
)
from app.services.alerta_service import AlertaService
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/", response_model=List[AlertaResponse])
def get_alertas(
    tipo_alerta: Optional[str] = None,
    nivel_prioridad: Optional[str] = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Listar alertas activas del usuario"""
    alertas = AlertaService.get_alertas_activas(
        db=db,
        user_id=current_user.user_id,
        tipo_alerta=tipo_alerta,
        nivel_prioridad=nivel_prioridad,
        skip=skip,
        limit=limit
    )
    
    # Agregar información adicional
    result = []
    for alerta in alertas:
        alerta_dict = AlertaResponse.from_orm(alerta).model_dump()
        if alerta.licitacion:
            alerta_dict['numero_licitacion'] = alerta.licitacion.numero_licitacion
        if alerta.documento:
            alerta_dict['nombre_documento'] = alerta.documento.nombre_documento
        result.append(AlertaResponse(**alerta_dict))
    
    return result

@router.get("/resumen")
def get_resumen_alertas(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Obtener resumen de alertas por prioridad"""
    return AlertaService.get_resumen_alertas(db, current_user.user_id)

@router.put("/{alerta_id}/leer", response_model=AlertaResponse)
def marcar_alerta_leida(
    alerta_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Marcar alerta como leída"""
    alerta = AlertaService.marcar_como_leida(db, alerta_id, current_user.user_id)
    if not alerta:
        raise HTTPException(status_code=404, detail="Alerta no encontrada")
    return alerta

@router.put("/{alerta_id}/resolver", response_model=AlertaResponse)
def marcar_alerta_resuelta(
    alerta_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Marcar alerta como resuelta"""
    alerta = AlertaService.marcar_como_resuelta(db, alerta_id, current_user.user_id)
    if not alerta:
        raise HTTPException(status_code=404, detail="Alerta no encontrada")
    return alerta

@router.get("/configuracion", response_model=ConfiguracionAlertasResponse)
def get_configuracion_alertas(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Obtener configuración de alertas del usuario"""
    config = AlertaService.get_or_create_configuracion(db, current_user.user_id)
    return config

@router.put("/configuracion", response_model=ConfiguracionAlertasResponse)
def update_configuracion_alertas(
    config_data: ConfiguracionAlertasUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Actualizar configuración de alertas"""
    config = AlertaService.get_or_create_configuracion(db, current_user.user_id)
    
    update_data = config_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(config, field, value)
    
    db.commit()
    db.refresh(config)
    return config

@router.post("/generar-todas")
def generar_todas_alertas(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["administrador"]))
):
    """Generar todas las alertas manualmente (solo admin)"""
    AlertaService.generar_alertas_documentos_vencidos(db)
    AlertaService.generar_alertas_contratos_proximos(db)
    AlertaService.generar_alertas_seguimientos(db)
    
    return {"message": "Alertas generadas exitosamente"}
```

---

## 🤖 Workers y Tareas Programadas {#workers}

**app/workers/alerta_worker.py**
```python
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.services.alerta_service import AlertaService
import logging

logger = logging.getLogger(__name__)

def generar_alertas_diarias():
    """Tarea programada para generar alertas todos los días"""
    db: Session = SessionLocal()
    try:
        logger.info("Iniciando generación de alertas diarias...")
        
        # Generar alertas de documentos
        AlertaService.generar_alertas_documentos_vencidos(db)
        logger.info("Alertas de documentos generadas")
        
        # Generar alertas de contratos
        AlertaService.generar_alertas_contratos_proximos(db)
        logger.info("Alertas de contratos generadas")
        
        # Generar alertas de seguimientos
        AlertaService.generar_alertas_seguimientos(db)
        logger.info("Alertas de seguimientos generadas")
        
        logger.info("Generación de alertas completada exitosamente")
        
    except Exception as e:
        logger.error(f"Error al generar alertas: {e}", exc_info=True)
    finally:
        db.close()

def limpiar_alertas_antiguas():
    """Limpiar alertas antiguas (más de 90 días)"""
    db: Session = SessionLocal()
    try:
        from datetime import datetime, timedelta
        from app.models.alerta import Alerta
        
        fecha_limite = datetime.now() - timedelta(days=90)
        
        # Archivar alertas antiguas resueltas
        alertas_antiguas = db.query(Alerta).filter(
            Alerta.estado_alerta == 'resuelta',
            Alerta.fecha_resuelta < fecha_limite
        ).update({"estado_alerta": "archivada"})
        
        db.commit()
        logger.info(f"Archivadas {alertas_antiguas} alertas antiguas")
        
    except Exception as e:
        logger.error(f"Error al limpiar alertas antiguas: {e}")
    finally:
        db.close()

def init_alerta_scheduler():
    """Inicializar scheduler de alertas"""
    scheduler = BackgroundScheduler()
    
    # Generar alertas todos los días a las 8:00 AM
    scheduler.add_job(
        generar_alertas_diarias,
        trigger=CronTrigger(hour=8, minute=0),
        id='generar_alertas_diarias',
        name='Generar alertas diarias',
        replace_existing=True
    )
    
    # Limpiar alertas antiguas semanalmente (domingos a las 2 AM)
    scheduler.add_job(
        limpiar_alertas_antiguas,
        trigger=CronTrigger(day_of_week='sun', hour=2, minute=0),
        id='limpiar_alertas_antiguas',
        name='Limpiar alertas antiguas',
        replace_existing=True
    )
    
    scheduler.start()
    logger.info("Scheduler de alertas iniciado")
    
    return scheduler
```

**app/main.py** (actualizar)
```python
from app.workers.alerta_worker import init_alerta_scheduler

# Después de crear la app
alerta_scheduler = init_alerta_scheduler()

@app.on_event("shutdown")
def shutdown_event():
    alerta_scheduler.shutdown()
```

---

## 📱 Implementación Frontend {#implementacion-frontend}

### 1. Modelo de Alerta

**lib/data/models/alerta_model.dart**
```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'alerta_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class AlertaModel {
  final int alertaId;
  final String tipoAlerta;
  final int? licitacionId;
  final int? documentoId;
  final String titulo;
  final String mensaje;
  final String nivelPrioridad;
  final String estadoAlerta;
  final DateTime fechaAlerta;
  final DateTime? fechaLeida;
  final bool requiereAccion;
  final String? urlAccion;
  final String? accionSugerida;
  final String? numeroLicitacion;
  final String? nombreDocumento;

  AlertaModel({
    required this.alertaId,
    required this.tipoAlerta,
    this.licitacionId,
    this.documentoId,
    required this.titulo,
    required this.mensaje,
    required this.nivelPrioridad,
    required this.estadoAlerta,
    required this.fechaAlerta,
    this.fechaLeida,
    required this.requiereAccion,
    this.urlAccion,
    this.accionSugerida,
    this.numeroLicitacion,
    this.nombreDocumento,
  });

  factory AlertaModel.fromJson(Map<String, dynamic> json) =>
      _$AlertaModelFromJson(json);

  Map<String, dynamic> toJson() => _$AlertaModelToJson(this);

  Color getPrioridadColor() {
    switch (nivelPrioridad) {
      case 'critica':
        return Colors.red;
      case 'alta':
        return Colors.orange;
      case 'media':
        return Colors.blue;
      case 'baja':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData getTipoIcon() {
    switch (tipoAlerta) {
      case 'documento_vencido':
      case 'documento_por_vencer':
        return Icons.description;
      case 'contrato_proximo_fin':
        return Icons.calendar_today;
      case 'garantia_vencida':
      case 'garantia_por_vencer':
        return Icons.account_balance;
      case 'seguimiento_pendiente':
        return Icons.flag;
      default:
        return Icons.notifications;
    }
  }

  String get prioridadFormatted {
    switch (nivelPrioridad) {
      case 'critica':
        return 'CRÍTICA';
      case 'alta':
        return 'ALTA';
      case 'media':
        return 'MEDIA';
      case 'baja':
        return 'BAJA';
      default:
        return nivelPrioridad.toUpperCase();
    }
  }
}
```

### 2. Dashboard de Alertas

**lib/presentation/screens/alertas/alertas_dashboard_screen.dart**
```dart
import 'package:flutter/material.dart';

class AlertasDashboardScreen extends StatelessWidget {
  const AlertasDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/alertas-configuracion');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumen de alertas
          _buildResumenCard(context),
          
          // Tabs de filtros
          _buildFiltrosTabs(),
          
          // Lista de alertas
          Expanded(
            child: _buildListaAlertas(),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _AlertaSummaryItem(
              count: 5,
              label: 'Críticas',
              color: Colors.red,
              icon: Icons.error,
            ),
            _AlertaSummaryItem(
              count: 12,
              label: 'Altas',
              color: Colors.orange,
              icon: Icons.warning,
            ),
            _AlertaSummaryItem(
              count: 8,
              label: 'Medias',
              color: Colors.blue,
              icon: Icons.info,
            ),
            _AlertaSummaryItem(
              count: 3,
              label: 'Bajas',
              color: Colors.grey,
              icon: Icons.notifications,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltrosTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(label: 'Todas', isSelected: true),
          const SizedBox(width: 8),
          _FilterChip(label: 'Documentos', isSelected: false),
          const SizedBox(width: 8),
          _FilterChip(label: 'Contratos', isSelected: false),
          const SizedBox(width: 8),
          _FilterChip(label: 'Seguimientos', isSelected: false),
        ],
      ),
    );
  }

  Widget _buildListaAlertas() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return _AlertaCard(
          titulo: 'Documento por vencer',
          mensaje: 'Certificación CCSS vence en 5 días',
          prioridad: index < 2 ? 'critica' : index < 5 ? 'alta' : 'media',
          fecha: DateTime.now().subtract(Duration(hours: index * 2)),
          requiereAccion: true,
          onTap: () {},
          onResolve: () {},
        );
      },
    );
  }
}

class _AlertaSummaryItem extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _AlertaSummaryItem({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            if (count > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (value) {},
      backgroundColor: Colors.grey.shade200,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
}

class _AlertaCard extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final String prioridad;
  final DateTime fecha;
  final bool requiereAccion;
  final VoidCallback onTap;
  final VoidCallback onResolve;

  const _AlertaCard({
    required this.titulo,
    required this.mensaje,
    required this.prioridad,
    required this.fecha,
    required this.requiereAccion,
    required this.onTap,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getPrioridadColor(prioridad);
    
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.warning, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                prioridad.toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTimeAgo(fecha),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                mensaje,
                style: const TextStyle(fontSize: 14),
              ),
              if (requiereAccion) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Ver detalle'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onResolve,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Resolver'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPrioridadColor(String prioridad) {
    switch (prioridad) {
      case 'critica':
        return Colors.red;
      case 'alta':
        return Colors.orange;
      case 'media':
        return Colors.blue;
      case 'baja':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    
    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} minutos';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} horas';
    } else {
      return 'Hace ${diff.inDays} días';
    }
  }
}
```

### 3. Configuración de Alertas

**lib/presentation/screens/alertas/configuracion_alertas_screen.dart**
```dart
import 'package:flutter/material.dart';

class ConfiguracionAlertasScreen extends StatefulWidget {
  const ConfiguracionAlertasScreen({Key? key}) : super(key: key);

  @override
  State<ConfiguracionAlertasScreen> createState() =>
      _ConfiguracionAlertasScreenState();
}

class _ConfiguracionAlertasScreenState
    extends State<ConfiguracionAlertasScreen> {
  bool _alertasDocumentos = true;
  int _diasDocumentos = 15;
  
  bool _alertasContratos = true;
  int _diasContratos = 30;
  
  bool _alertasGarantias = true;
  int _diasGarantias = 15;
  
  bool _alertasSeguimientos = true;
  
  bool _notificarEmail = true;
  bool _resumenDiario = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Alertas'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Documentos
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Documentos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Alertas de vencimiento'),
                    subtitle: const Text('Recibir alertas de documentos por vencer'),
                    value: _alertasDocumentos,
                    onChanged: (value) =>
                        setState(() => _alertasDocumentos = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_alertasDocumentos) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Alertar con'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Slider(
                            value: _diasDocumentos.toDouble(),
                            min: 5,
                            max: 60,
                            divisions: 11,
                            label: '$_diasDocumentos días',
                            onChanged: (value) =>
                                setState(() => _diasDocumentos = value.toInt()),
                          ),
                        ),
                        Text('$_diasDocumentos días'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contratos
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contratos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Alertas de finalización'),
                    subtitle: const Text('Recibir alertas de contratos próximos a finalizar'),
                    value: _alertasContratos,
                    onChanged: (value) =>
                        setState(() => _alertasContratos = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_alertasContratos) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Alertar con'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Slider(
                            value: _diasContratos.toDouble(),
                            min: 15,
                            max: 90,
                            divisions: 15,
                            label: '$_diasContratos días',
                            onChanged: (value) =>
                                setState(() => _diasContratos = value.toInt()),
                          ),
                        ),
                        Text('$_diasContratos días'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notificaciones
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notificaciones',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Notificaciones por email'),
                    subtitle: const Text('Recibir alertas por correo electrónico'),
                    value: _notificarEmail,
                    onChanged: (value) =>
                        setState(() => _notificarEmail = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Resumen diario'),
                    subtitle: const Text('Recibir resumen diario de alertas'),
                    value: _resumenDiario,
                    onChanged: (value) =>
                        setState(() => _resumenDiario = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Botón guardar
          ElevatedButton(
            onPressed: _guardarConfiguracion,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Guardar Configuración'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarConfiguracion() async {
    // Aquí integrarías con tu repository
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración guardada')),
    );
  }
}
```

---

## 🧪 Testing {#testing}

**tests/test_alertas.py**
```python
def test_generar_alertas_documentos(client, auth_token):
    response = client.post(
        "/api/v1/alertas/generar-todas",
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert response.status_code == 200

def test_get_alertas_activas(client, auth_token):
    response = client.get(
        "/api/v1/alertas/",
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_marcar_alerta_leida(client, auth_token, alerta_id):
    response = client.put(
        f"/api/v1/alertas/{alerta_id}/leer",
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert response.status_code == 200
    assert response.json()["estado_alerta"] == "leida"

def test_get_resumen_alertas(client, auth_token):
    response = client.get(
        "/api/v1/alertas/resumen",
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert response.status_code == 200
    assert "critica" in response.json()
    assert "total" in response.json()
```

---

## ✅ Checklist de Completitud {#checklist}

### Backend
- [ ] Modelos Alerta, ConfiguracionAlertas, HistorialNotificacion creados
- [ ] Migraciones aplicadas
- [ ] Schemas con validaciones
- [ ] Service layer con lógica de generación de alertas
- [ ] Endpoint de listado con filtros
- [ ] Endpoint de resumen
- [ ] Endpoint de marcar como leída
- [ ] Endpoint de marcar como resuelta
- [ ] Endpoint de configuración CRUD
- [ ] Worker programado funcionando
- [ ] Generación automática de alertas diarias
- [ ] Limpieza de alertas antiguas
- [ ] Cálculo de prioridades automático
- [ ] Tests unitarios pasando

### Frontend
- [ ] Modelo AlertaModel creado
- [ ] Repository implementado
- [ ] Dashboard con resumen de alertas
- [ ] Lista de alertas con filtros
- [ ] Indicadores visuales por prioridad
- [ ] Pantalla de configuración
- [ ] Sliders para días de alerta
- [ ] Switches para activar/desactivar alertas
- [ ] Botones de acción (leer, resolver)
- [ ] Navegación desde alertas a detalles
- [ ] Notificaciones en tiempo real (badge)

### Integración
- [ ] Alertas se generan automáticamente
- [ ] Filtros funcionan correctamente
- [ ] Estados se actualizan correctamente
- [ ] Configuración se guarda y aplica
- [ ] Resumen refleja datos reales
- [ ] Worker ejecuta en horario configurado

---

## 📊 Criterios de Aceptación

1. ✅ Sistema genera alertas automáticamente cada día
2. ✅ Alertas se priorizan correctamente (crítica, alta, media, baja)
3. ✅ Usuario puede ver resumen de alertas por prioridad
4. ✅ Usuario puede filtrar alertas por tipo
5. ✅ Usuario puede marcar alertas como leídas/resueltas
6. ✅ Usuario puede configurar días de anticipación
7. ✅ Usuario puede activar/desactivar tipos de alertas
8. ✅ Dashboard muestra contadores en tiempo real
9. ✅ Alertas antiguas se archivan automáticamente
10. ✅ Sistema calcula prioridades basado en urgencia

---

## ➡️ Próximos Pasos

**FASE 7 y 8**: Ya documentadas en archivos anteriores
- Reportes y Analytics
- Auditoría y Refinamiento

---

**✅ FASE 6 COMPLETADA**

**🎉 TODAS LAS FASES DETALLADAS COMPLETAS (1-6)**

Las fases 7 y 8 ya están documentadas en el archivo "FASES 7 y 8" que generé anteriormente.