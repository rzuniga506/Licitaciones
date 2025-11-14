"""
Dashboard endpoints for general statistics and metrics.
"""
from typing import Optional
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date, datetime, timedelta

from app.core.security import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.models.cliente import Cliente
from app.models.licitacion import Licitacion
from app.models.documento import Documento
from app.models.alerta import Alerta

router = APIRouter()


@router.get("/stats")
async def get_dashboard_stats(
    fecha_desde: Optional[date] = None,
    fecha_hasta: Optional[date] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get general dashboard statistics.

    Provides an overview of the entire system including:
    - Total counts of main entities
    - Recent activity
    - Alerts and notifications
    - Quick metrics

    Args:
        fecha_desde: Start date for filtering (optional)
        fecha_hasta: End date for filtering (optional)
        db: Database session
        current_user: Current authenticated user

    Returns:
        Dictionary with dashboard statistics
    """
    # Base queries
    clientes_query = db.query(Cliente).filter(Cliente.is_deleted == False)
    licitaciones_query = db.query(Licitacion).filter(Licitacion.is_deleted == False)
    documentos_query = db.query(Documento).filter(Documento.is_deleted == False)
    alertas_query = db.query(Alerta).filter(Alerta.is_deleted == False)

    # Apply date filters if provided
    if fecha_desde:
        licitaciones_query = licitaciones_query.filter(Licitacion.created_at >= fecha_desde)
    if fecha_hasta:
        licitaciones_query = licitaciones_query.filter(Licitacion.created_at <= fecha_hasta)

    # Total counts
    total_clientes = clientes_query.count()
    total_licitaciones = licitaciones_query.count()
    total_documentos = documentos_query.count()

    # Licitaciones by estado
    licitaciones_por_estado = {}
    estados = db.query(
        Licitacion.estado_licitacion,
        func.count(Licitacion.licitacion_id)
    ).filter(
        Licitacion.is_deleted == False
    ).group_by(Licitacion.estado_licitacion).all()

    for estado, count in estados:
        licitaciones_por_estado[estado] = count

    # Active licitaciones (in progress states)
    estados_activos = ["en_preparacion", "presentada", "en_evaluacion", "adjudicada", "en_ejecucion"]
    licitaciones_activas = db.query(Licitacion).filter(
        Licitacion.is_deleted == False,
        Licitacion.estado_licitacion.in_(estados_activos)
    ).count()

    # Calculate success rate
    total_presentadas = db.query(Licitacion).filter(
        Licitacion.is_deleted == False,
        Licitacion.estado_licitacion.in_(["adjudicada", "finalizada", "rechazada", "desierta"])
    ).count()

    adjudicadas = licitaciones_por_estado.get("adjudicada", 0) + licitaciones_por_estado.get("finalizada", 0)
    tasa_exito = (adjudicadas / total_presentadas * 100) if total_presentadas > 0 else 0

    # Financial metrics
    monto_total_ofertado = db.query(
        func.sum(Licitacion.monto_ofertado)
    ).filter(
        Licitacion.is_deleted == False,
        Licitacion.monto_ofertado.isnot(None)
    ).scalar() or 0

    monto_total_adjudicado = db.query(
        func.sum(Licitacion.monto_adjudicado)
    ).filter(
        Licitacion.is_deleted == False,
        Licitacion.estado_licitacion.in_(["adjudicada", "en_ejecucion", "finalizada"]),
        Licitacion.monto_adjudicado.isnot(None)
    ).scalar() or 0

    # Recent activity (last 30 days)
    fecha_30_dias = datetime.now() - timedelta(days=30)

    nuevas_licitaciones_mes = db.query(Licitacion).filter(
        Licitacion.is_deleted == False,
        Licitacion.created_at >= fecha_30_dias
    ).count()

    nuevos_documentos_mes = db.query(Documento).filter(
        Documento.is_deleted == False,
        Documento.created_at >= fecha_30_dias
    ).count()

    # Alerts
    alertas_activas = alertas_query.filter(
        Alerta.estado_alerta == "activa"
    ).count()

    alertas_criticas = alertas_query.filter(
        Alerta.estado_alerta == "activa",
        Alerta.nivel_prioridad == "critica"
    ).count()

    alertas_requieren_accion = alertas_query.filter(
        Alerta.estado_alerta == "activa",
        Alerta.requiere_accion == True
    ).count()

    # Upcoming deadlines (next 15 days)
    fecha_15_dias = date.today() + timedelta(days=15)

    licitaciones_proximas = db.query(Licitacion).filter(
        Licitacion.is_deleted == False,
        Licitacion.estado_licitacion.in_(["en_preparacion", "presentada"]),
        Licitacion.fecha_presentacion.isnot(None),
        Licitacion.fecha_presentacion <= fecha_15_dias,
        Licitacion.fecha_presentacion >= date.today()
    ).count()

    documentos_por_vencer = db.query(Documento).filter(
        Documento.is_deleted == False,
        Documento.estado_documento == "activo",
        Documento.fecha_vencimiento.isnot(None),
        Documento.fecha_vencimiento <= fecha_15_dias,
        Documento.fecha_vencimiento >= date.today()
    ).count()

    # Top clientes (by number of licitaciones)
    top_clientes = db.query(
        Cliente.cliente_id,
        Cliente.nombre_cliente,
        func.count(Licitacion.licitacion_id).label('total_licitaciones')
    ).join(
        Licitacion, Licitacion.cliente_id == Cliente.cliente_id
    ).filter(
        Cliente.is_deleted == False,
        Licitacion.is_deleted == False
    ).group_by(
        Cliente.cliente_id,
        Cliente.nombre_cliente
    ).order_by(
        func.count(Licitacion.licitacion_id).desc()
    ).limit(5).all()

    top_clientes_list = [
        {
            "cliente_id": cliente_id,
            "nombre_cliente": nombre,
            "total_licitaciones": total
        }
        for cliente_id, nombre, total in top_clientes
    ]

    return {
        # Totals
        "total_clientes": total_clientes,
        "total_licitaciones": total_licitaciones,
        "total_documentos": total_documentos,
        "licitaciones_activas": licitaciones_activas,

        # Estados
        "licitaciones_por_estado": licitaciones_por_estado,

        # Financial
        "monto_total_ofertado": float(monto_total_ofertado),
        "monto_total_adjudicado": float(monto_total_adjudicado),
        "tasa_exito": round(tasa_exito, 2),

        # Recent activity
        "nuevas_licitaciones_mes": nuevas_licitaciones_mes,
        "nuevos_documentos_mes": nuevos_documentos_mes,

        # Alerts
        "alertas_activas": alertas_activas,
        "alertas_criticas": alertas_criticas,
        "alertas_requieren_accion": alertas_requieren_accion,

        # Upcoming deadlines
        "licitaciones_proximas_15_dias": licitaciones_proximas,
        "documentos_por_vencer_15_dias": documentos_por_vencer,

        # Top performers
        "top_clientes": top_clientes_list,

        # Metadata
        "fecha_consulta": datetime.now().isoformat(),
        "periodo_filtro": {
            "desde": fecha_desde.isoformat() if fecha_desde else None,
            "hasta": fecha_hasta.isoformat() if fecha_hasta else None
        }
    }


@router.get("/activity")
async def get_recent_activity(
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get recent activity in the system.

    Args:
        limit: Maximum number of activities to return (default: 20, max: 100)
        db: Database session
        current_user: Current authenticated user

    Returns:
        List of recent activities
    """
    if limit > 100:
        limit = 100

    # Get recent licitaciones
    recent_licitaciones = db.query(Licitacion).filter(
        Licitacion.is_deleted == False
    ).order_by(Licitacion.created_at.desc()).limit(limit // 2).all()

    # Get recent documentos
    recent_documentos = db.query(Documento).filter(
        Documento.is_deleted == False
    ).order_by(Documento.created_at.desc()).limit(limit // 2).all()

    # Combine and format activities
    activities = []

    for lic in recent_licitaciones:
        activities.append({
            "tipo": "licitacion",
            "accion": "creada",
            "id": lic.licitacion_id,
            "titulo": lic.nombre_licitacion,
            "numero": lic.numero_licitacion,
            "fecha": lic.created_at.isoformat(),
            "estado": lic.estado_licitacion
        })

    for doc in recent_documentos:
        activities.append({
            "tipo": "documento",
            "accion": "subido",
            "id": doc.documento_id,
            "titulo": doc.nombre_documento,
            "fecha": doc.created_at.isoformat(),
            "tipo_documento": doc.tipo_documento
        })

    # Sort by fecha
    activities.sort(key=lambda x: x["fecha"], reverse=True)

    return {
        "total": len(activities),
        "activities": activities[:limit]
    }
