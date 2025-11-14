"""
Automated alert generation tasks.

This module contains tasks that run periodically to generate alerts
for various system events like expiring documents, upcoming deadlines, etc.
"""
from datetime import date, datetime, timedelta
from typing import List, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func
import logging

from app.db.session import get_db
from app.models.documento import Documento
from app.models.licitacion import Licitacion
from app.models.crm import InteraccionCliente
from app.models.alerta import Alerta, ConfiguracionAlertas
from app.models.ampliacion import Ampliacion, Prorroga

logger = logging.getLogger(__name__)


class AlertGenerator:
    """Service for generating automated alerts."""

    @staticmethod
    def generate_documento_alerts(db: Session) -> int:
        """
        Generate alerts for expiring and expired documents.

        Checks all active documents and creates alerts for users based on their
        configuration preferences.

        Returns:
            Number of alerts created
        """
        alerts_created = 0
        today = date.today()

        # Get all user configurations
        configs = db.query(ConfiguracionAlertas).filter(
            ConfiguracionAlertas.alertas_documentos_vencidos == True
        ).all()

        for config in configs:
            dias_alerta = config.dias_alerta_documentos or 15
            fecha_limite = today + timedelta(days=dias_alerta)

            # Find documents expiring soon for this user's scope
            documentos_por_vencer = db.query(Documento).filter(
                Documento.is_deleted == False,
                Documento.estado_documento == "activo",
                Documento.fecha_vencimiento.isnot(None),
                Documento.fecha_vencimiento <= fecha_limite,
                Documento.fecha_vencimiento > today
            ).all()

            for doc in documentos_por_vencer:
                dias_restantes = (doc.fecha_vencimiento - today).days

                # Check if alert already exists for this document
                existing_alert = db.query(Alerta).filter(
                    Alerta.user_id == config.user_id,
                    Alerta.documento_id == doc.documento_id,
                    Alerta.tipo_alerta == "documento_por_vencer",
                    Alerta.estado_alerta.in_(["activa", "leida"])
                ).first()

                if not existing_alert:
                    # Determine priority based on days remaining
                    if dias_restantes <= 3:
                        prioridad = "critica"
                    elif dias_restantes <= 7:
                        prioridad = "alta"
                    else:
                        prioridad = "media"

                    alert = Alerta(
                        user_id=config.user_id,
                        tipo_alerta="documento_por_vencer",
                        titulo=f"Documento próximo a vencer: {doc.nombre_documento}",
                        mensaje=f"El documento '{doc.nombre_documento}' vence en {dias_restantes} días (el {doc.fecha_vencimiento.strftime('%d/%m/%Y')})",
                        nivel_prioridad=prioridad,
                        estado_alerta="activa",
                        requiere_accion=True,
                        accion_sugerida="Renovar o actualizar el documento antes de su vencimiento",
                        url_accion=f"/documentos/{doc.documento_id}",
                        documento_id=doc.documento_id,
                        licitacion_id=doc.licitacion_id,
                        fecha_alerta=datetime.now(),
                        created_by=1  # System user
                    )
                    db.add(alert)
                    alerts_created += 1

            # Find expired documents
            documentos_vencidos = db.query(Documento).filter(
                Documento.is_deleted == False,
                Documento.estado_documento == "activo",
                Documento.fecha_vencimiento.isnot(None),
                Documento.fecha_vencimiento < today
            ).all()

            for doc in documentos_vencidos:
                existing_alert = db.query(Alerta).filter(
                    Alerta.user_id == config.user_id,
                    Alerta.documento_id == doc.documento_id,
                    Alerta.tipo_alerta == "documento_vencido",
                    Alerta.estado_alerta.in_(["activa", "leida"])
                ).first()

                if not existing_alert:
                    alert = Alerta(
                        user_id=config.user_id,
                        tipo_alerta="documento_vencido",
                        titulo=f"Documento vencido: {doc.nombre_documento}",
                        mensaje=f"El documento '{doc.nombre_documento}' venció el {doc.fecha_vencimiento.strftime('%d/%m/%Y')}",
                        nivel_prioridad="critica",
                        estado_alerta="activa",
                        requiere_accion=True,
                        accion_sugerida="Renovar el documento urgentemente",
                        url_accion=f"/documentos/{doc.documento_id}",
                        documento_id=doc.documento_id,
                        licitacion_id=doc.licitacion_id,
                        fecha_alerta=datetime.now(),
                        created_by=1
                    )
                    db.add(alert)
                    alerts_created += 1

        db.commit()
        logger.info(f"Created {alerts_created} document alerts")
        return alerts_created

    @staticmethod
    def generate_licitacion_alerts(db: Session) -> int:
        """
        Generate alerts for upcoming licitacion deadlines.

        Returns:
            Number of alerts created
        """
        alerts_created = 0
        today = date.today()

        # Get all user configurations
        configs = db.query(ConfiguracionAlertas).filter(
            ConfiguracionAlertas.alertas_licitaciones_proximas == True
        ).all()

        for config in configs:
            dias_alerta = config.dias_alerta_licitaciones or 7
            fecha_limite = today + timedelta(days=dias_alerta)

            # Find licitaciones with upcoming presentation dates
            licitaciones_proximas = db.query(Licitacion).filter(
                Licitacion.is_deleted == False,
                Licitacion.estado_licitacion.in_(["en_preparacion", "publicada"]),
                Licitacion.fecha_presentacion.isnot(None),
                Licitacion.fecha_presentacion <= fecha_limite,
                Licitacion.fecha_presentacion >= today
            ).all()

            for lic in licitaciones_proximas:
                dias_restantes = (lic.fecha_presentacion - today).days

                existing_alert = db.query(Alerta).filter(
                    Alerta.user_id == config.user_id,
                    Alerta.licitacion_id == lic.licitacion_id,
                    Alerta.tipo_alerta == "licitacion_proxima",
                    Alerta.estado_alerta.in_(["activa", "leida"])
                ).first()

                if not existing_alert:
                    if dias_restantes <= 2:
                        prioridad = "critica"
                    elif dias_restantes <= 5:
                        prioridad = "alta"
                    else:
                        prioridad = "media"

                    alert = Alerta(
                        user_id=config.user_id,
                        tipo_alerta="licitacion_proxima",
                        titulo=f"Licitación próxima a vencer: {lic.numero_licitacion}",
                        mensaje=f"La presentación de '{lic.titulo_licitacion}' vence en {dias_restantes} días (el {lic.fecha_presentacion.strftime('%d/%m/%Y')})",
                        nivel_prioridad=prioridad,
                        estado_alerta="activa",
                        requiere_accion=True,
                        accion_sugerida="Completar y presentar la oferta antes de la fecha límite",
                        url_accion=f"/licitaciones/{lic.licitacion_id}",
                        licitacion_id=lic.licitacion_id,
                        cliente_id=lic.cliente_id,
                        fecha_alerta=datetime.now(),
                        created_by=1
                    )
                    db.add(alert)
                    alerts_created += 1

        db.commit()
        logger.info(f"Created {alerts_created} licitacion alerts")
        return alerts_created

    @staticmethod
    def generate_contrato_alerts(db: Session) -> int:
        """
        Generate alerts for contracts nearing end date.

        Returns:
            Number of alerts created
        """
        alerts_created = 0
        today = date.today()

        configs = db.query(ConfiguracionAlertas).filter(
            ConfiguracionAlertas.alertas_contratos_proximos == True
        ).all()

        for config in configs:
            dias_alerta = config.dias_alerta_contratos or 30
            fecha_limite = today + timedelta(days=dias_alerta)

            # Find contracts (licitaciones adjudicadas) ending soon
            contratos_proximos = db.query(Licitacion).filter(
                Licitacion.is_deleted == False,
                Licitacion.estado_licitacion == "en_ejecucion",
                Licitacion.fecha_fin_contrato.isnot(None),
                Licitacion.fecha_fin_contrato <= fecha_limite,
                Licitacion.fecha_fin_contrato >= today
            ).all()

            for contrato in contratos_proximos:
                dias_restantes = (contrato.fecha_fin_contrato - today).days

                existing_alert = db.query(Alerta).filter(
                    Alerta.user_id == config.user_id,
                    Alerta.licitacion_id == contrato.licitacion_id,
                    Alerta.tipo_alerta == "contrato_proximo_fin",
                    Alerta.estado_alerta.in_(["activa", "leida"])
                ).first()

                if not existing_alert:
                    if dias_restantes <= 15:
                        prioridad = "alta"
                    else:
                        prioridad = "media"

                    alert = Alerta(
                        user_id=config.user_id,
                        tipo_alerta="contrato_proximo_fin",
                        titulo=f"Contrato próximo a finalizar: {contrato.numero_licitacion}",
                        mensaje=f"El contrato '{contrato.titulo_licitacion}' finaliza en {dias_restantes} días (el {contrato.fecha_fin_contrato.strftime('%d/%m/%Y')})",
                        nivel_prioridad=prioridad,
                        estado_alerta="activa",
                        requiere_accion=True,
                        accion_sugerida="Evaluar renovación o cierre del contrato",
                        url_accion=f"/licitaciones/{contrato.licitacion_id}",
                        licitacion_id=contrato.licitacion_id,
                        cliente_id=contrato.cliente_id,
                        fecha_alerta=datetime.now(),
                        created_by=1
                    )
                    db.add(alert)
                    alerts_created += 1

        db.commit()
        logger.info(f"Created {alerts_created} contrato alerts")
        return alerts_created

    @staticmethod
    def generate_garantia_alerts(db: Session) -> int:
        """
        Generate alerts for guarantees nearing expiration.

        Returns:
            Number of alerts created
        """
        alerts_created = 0
        today = date.today()

        configs = db.query(ConfiguracionAlertas).filter(
            ConfiguracionAlertas.alertas_garantias == True
        ).all()

        for config in configs:
            dias_alerta = config.dias_alerta_garantias or 15
            fecha_limite = today + timedelta(days=dias_alerta)

            # Find guarantees expiring soon
            garantias_por_vencer = db.query(Licitacion).filter(
                Licitacion.is_deleted == False,
                Licitacion.estado_licitacion.in_(["presentada", "adjudicada", "en_ejecucion"]),
                Licitacion.fecha_vencimiento_garantia.isnot(None),
                Licitacion.fecha_vencimiento_garantia <= fecha_limite,
                Licitacion.fecha_vencimiento_garantia > today
            ).all()

            for lic in garantias_por_vencer:
                dias_restantes = (lic.fecha_vencimiento_garantia - today).days

                existing_alert = db.query(Alerta).filter(
                    Alerta.user_id == config.user_id,
                    Alerta.licitacion_id == lic.licitacion_id,
                    Alerta.tipo_alerta == "garantia_por_vencer",
                    Alerta.estado_alerta.in_(["activa", "leida"])
                ).first()

                if not existing_alert:
                    if dias_restantes <= 5:
                        prioridad = "critica"
                    elif dias_restantes <= 10:
                        prioridad = "alta"
                    else:
                        prioridad = "media"

                    alert = Alerta(
                        user_id=config.user_id,
                        tipo_alerta="garantia_por_vencer",
                        titulo=f"Garantía próxima a vencer: {lic.numero_licitacion}",
                        mensaje=f"La garantía de '{lic.titulo_licitacion}' vence en {dias_restantes} días (el {lic.fecha_vencimiento_garantia.strftime('%d/%m/%Y')})",
                        nivel_prioridad=prioridad,
                        estado_alerta="activa",
                        requiere_accion=True,
                        accion_sugerida="Renovar la garantía antes de su vencimiento",
                        url_accion=f"/licitaciones/{lic.licitacion_id}",
                        licitacion_id=lic.licitacion_id,
                        cliente_id=lic.cliente_id,
                        fecha_alerta=datetime.now(),
                        created_by=1
                    )
                    db.add(alert)
                    alerts_created += 1

            # Find expired guarantees
            garantias_vencidas = db.query(Licitacion).filter(
                Licitacion.is_deleted == False,
                Licitacion.estado_licitacion.in_(["presentada", "adjudicada", "en_ejecucion"]),
                Licitacion.fecha_vencimiento_garantia.isnot(None),
                Licitacion.fecha_vencimiento_garantia < today
            ).all()

            for lic in garantias_vencidas:
                existing_alert = db.query(Alerta).filter(
                    Alerta.user_id == config.user_id,
                    Alerta.licitacion_id == lic.licitacion_id,
                    Alerta.tipo_alerta == "garantia_vencida",
                    Alerta.estado_alerta.in_(["activa", "leida"])
                ).first()

                if not existing_alert:
                    alert = Alerta(
                        user_id=config.user_id,
                        tipo_alerta="garantia_vencida",
                        titulo=f"Garantía vencida: {lic.numero_licitacion}",
                        mensaje=f"La garantía de '{lic.titulo_licitacion}' venció el {lic.fecha_vencimiento_garantia.strftime('%d/%m/%Y')}",
                        nivel_prioridad="critica",
                        estado_alerta="activa",
                        requiere_accion=True,
                        accion_sugerida="Renovar garantía urgentemente para evitar penalizaciones",
                        url_accion=f"/licitaciones/{lic.licitacion_id}",
                        licitacion_id=lic.licitacion_id,
                        cliente_id=lic.cliente_id,
                        fecha_alerta=datetime.now(),
                        created_by=1
                    )
                    db.add(alert)
                    alerts_created += 1

        db.commit()
        logger.info(f"Created {alerts_created} garantia alerts")
        return alerts_created

    @staticmethod
    def generate_seguimiento_alerts(db: Session) -> int:
        """
        Generate alerts for pending CRM follow-ups.

        Returns:
            Number of alerts created
        """
        alerts_created = 0
        today = date.today()
        fecha_limite = today + timedelta(days=7)

        # Find interactions requiring follow-up
        seguimientos_pendientes = db.query(InteraccionCliente).filter(
            InteraccionCliente.is_deleted == False,
            InteraccionCliente.requiere_seguimiento == True,
            InteraccionCliente.fecha_seguimiento.isnot(None),
            InteraccionCliente.fecha_seguimiento <= fecha_limite
        ).all()

        # Group by user (use created_by as the responsible user)
        for interaccion in seguimientos_pendientes:
            user_id = interaccion.created_by

            existing_alert = db.query(Alerta).filter(
                Alerta.user_id == user_id,
                Alerta.interaccion_id == interaccion.interaccion_id,
                Alerta.tipo_alerta == "seguimiento_pendiente",
                Alerta.estado_alerta.in_(["activa", "leida"])
            ).first()

            if not existing_alert:
                dias_restantes = (interaccion.fecha_seguimiento - today).days

                if dias_restantes < 0:
                    prioridad = "critica"
                    titulo = f"Seguimiento atrasado"
                    mensaje = f"Seguimiento con cliente pendiente desde hace {abs(dias_restantes)} días"
                elif dias_restantes == 0:
                    prioridad = "alta"
                    titulo = f"Seguimiento para hoy"
                    mensaje = f"Seguimiento con cliente programado para hoy"
                else:
                    prioridad = "media"
                    titulo = f"Seguimiento próximo"
                    mensaje = f"Seguimiento con cliente en {dias_restantes} días (el {interaccion.fecha_seguimiento.strftime('%d/%m/%Y')})"

                alert = Alerta(
                    user_id=user_id,
                    tipo_alerta="seguimiento_pendiente",
                    titulo=titulo,
                    mensaje=mensaje,
                    nivel_prioridad=prioridad,
                    estado_alerta="activa",
                    requiere_accion=True,
                    accion_sugerida="Realizar seguimiento con el cliente",
                    url_accion=f"/crm/interacciones/{interaccion.interaccion_id}",
                    interaccion_id=interaccion.interaccion_id,
                    cliente_id=interaccion.cliente_id,
                    fecha_alerta=datetime.now(),
                    created_by=1
                )
                db.add(alert)
                alerts_created += 1

        db.commit()
        logger.info(f"Created {alerts_created} seguimiento alerts")
        return alerts_created

    @staticmethod
    def generate_ampliacion_alerts(db: Session) -> int:
        """
        Generate alerts for pending ampliaciones requiring approval.

        Returns:
            Number of alerts created
        """
        alerts_created = 0

        # Find pending ampliaciones older than 3 days
        tres_dias_atras = datetime.now() - timedelta(days=3)

        ampliaciones_pendientes = db.query(Ampliacion).filter(
            Ampliacion.is_deleted == False,
            Ampliacion.estado_ampliacion == "pendiente",
            Ampliacion.created_at < tres_dias_atras
        ).all()

        # Alert coordinators and admins (user_id 1 and 2 typically)
        # In production, this should query users with coordinator/admin role
        coordinators = [1, 2]

        for ampliacion in ampliaciones_pendientes:
            for user_id in coordinators:
                existing_alert = db.query(Alerta).filter(
                    Alerta.user_id == user_id,
                    Alerta.ampliacion_id == ampliacion.ampliacion_id,
                    Alerta.tipo_alerta == "ampliacion_pendiente",
                    Alerta.estado_alerta.in_(["activa", "leida"])
                ).first()

                if not existing_alert:
                    dias_pendiente = (datetime.now() - ampliacion.created_at).days

                    prioridad = "alta" if dias_pendiente > 7 else "media"

                    alert = Alerta(
                        user_id=user_id,
                        tipo_alerta="ampliacion_pendiente",
                        titulo=f"Ampliación pendiente de aprobación",
                        mensaje=f"Ampliación tipo '{ampliacion.tipo_ampliacion}' pendiente hace {dias_pendiente} días",
                        nivel_prioridad=prioridad,
                        estado_alerta="activa",
                        requiere_accion=True,
                        accion_sugerida="Revisar y aprobar/rechazar la ampliación",
                        url_accion=f"/modificaciones/ampliaciones/{ampliacion.ampliacion_id}",
                        ampliacion_id=ampliacion.ampliacion_id,
                        licitacion_id=ampliacion.licitacion_id,
                        fecha_alerta=datetime.now(),
                        created_by=1
                    )
                    db.add(alert)
                    alerts_created += 1

        # Same for prorrogas
        prorrogas_pendientes = db.query(Prorroga).filter(
            Prorroga.is_deleted == False,
            Prorroga.estado_prorroga == "pendiente",
            Prorroga.created_at < tres_dias_atras
        ).all()

        for prorroga in prorrogas_pendientes:
            for user_id in coordinators:
                existing_alert = db.query(Alerta).filter(
                    Alerta.user_id == user_id,
                    Alerta.prorroga_id == prorroga.prorroga_id,
                    Alerta.tipo_alerta == "ampliacion_pendiente",
                    Alerta.estado_alerta.in_(["activa", "leida"])
                ).first()

                if not existing_alert:
                    dias_pendiente = (datetime.now() - prorroga.created_at).days

                    prioridad = "alta" if dias_pendiente > 7 else "media"

                    alert = Alerta(
                        user_id=user_id,
                        tipo_alerta="ampliacion_pendiente",
                        titulo=f"Prórroga pendiente de aprobación",
                        mensaje=f"Prórroga de {prorroga.dias_prorrogados} días pendiente hace {dias_pendiente} días",
                        nivel_prioridad=prioridad,
                        estado_alerta="activa",
                        requiere_accion=True,
                        accion_sugerida="Revisar y aprobar/rechazar la prórroga",
                        url_accion=f"/modificaciones/prorrogas/{prorroga.prorroga_id}",
                        prorroga_id=prorroga.prorroga_id,
                        licitacion_id=prorroga.licitacion_id,
                        fecha_alerta=datetime.now(),
                        created_by=1
                    )
                    db.add(alert)
                    alerts_created += 1

        db.commit()
        logger.info(f"Created {alerts_created} ampliacion/prorroga alerts")
        return alerts_created

    @staticmethod
    def cleanup_old_alerts(db: Session, days: int = 90) -> int:
        """
        Archive old resolved alerts.

        Args:
            db: Database session
            days: Archive alerts older than this many days

        Returns:
            Number of alerts archived
        """
        cutoff_date = datetime.now() - timedelta(days=days)

        result = db.query(Alerta).filter(
            Alerta.estado_alerta == "resuelta",
            Alerta.fecha_resuelta < cutoff_date
        ).update({"estado_alerta": "archivada"})

        db.commit()
        logger.info(f"Archived {result} old alerts")
        return result

    @staticmethod
    def run_all_alert_generation(db: Session) -> Dict[str, int]:
        """
        Run all alert generation tasks.

        Returns:
            Dictionary with counts for each alert type
        """
        logger.info("Starting automated alert generation")

        results = {
            "documentos": AlertGenerator.generate_documento_alerts(db),
            "licitaciones": AlertGenerator.generate_licitacion_alerts(db),
            "contratos": AlertGenerator.generate_contrato_alerts(db),
            "garantias": AlertGenerator.generate_garantia_alerts(db),
            "seguimientos": AlertGenerator.generate_seguimiento_alerts(db),
            "ampliaciones": AlertGenerator.generate_ampliacion_alerts(db),
            "archived": AlertGenerator.cleanup_old_alerts(db)
        }

        total = sum(v for k, v in results.items() if k != "archived")
        logger.info(f"Alert generation completed. Total alerts created: {total}")
        logger.info(f"Details: {results}")

        return results
