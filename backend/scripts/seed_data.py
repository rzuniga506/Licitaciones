#!/usr/bin/env python3
"""
Seed script to populate database with sample data.

This script creates sample data for testing the licitaciones system,
including clientes, licitaciones, documentos, contactos, and interactions.

Usage:
    python scripts/seed_data.py           # Create all sample data
    python scripts/seed_data.py --clear   # Clear existing data first
"""
import sys
import argparse
from pathlib import Path
from datetime import date, datetime, timedelta
from decimal import Decimal

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.db.session import SessionLocal
from app.models.user import User
from app.models.cliente import Cliente
from app.models.licitacion import Licitacion
from app.models.documento import Documento
from app.models.crm import Contacto, InteraccionCliente
from app.models.ampliacion import Ampliacion, Prorroga
from app.models.alerta import ConfiguracionAlertas
from app.core.security import get_password_hash


def clear_data(db: SessionLocal):
    """Clear all existing data (except users)."""
    print("Clearing existing data...")

    db.query(InteraccionCliente).delete()
    db.query(Contacto).delete()
    db.query(Prorroga).delete()
    db.query(Ampliacion).delete()
    db.query(Documento).delete()
    db.query(Licitacion).delete()
    db.query(Cliente).delete()

    db.commit()
    print("✓ Data cleared")


def create_sample_clientes(db: SessionLocal):
    """Create sample clientes."""
    print("\nCreating sample clientes...")

    clientes = [
        {
            "nombre_cliente": "Ministerio de Educación Pública",
            "tipo_cliente": "publico",
            "identificacion": "4-000-123456",
            "sector_industria": "Educación",
            "telefono_principal": "2222-1111",
            "email_principal": "compras@mep.go.cr",
            "direccion": "San José, Costa Rica",
            "sitio_web": "https://www.mep.go.cr",
            "nivel_importancia": "alto",
            "is_active": True
        },
        {
            "nombre_cliente": "Instituto Costarricense de Electricidad",
            "tipo_cliente": "publico",
            "identificacion": "4-000-042139",
            "sector_industria": "Energía",
            "telefono_principal": "2000-7000",
            "email_principal": "proveeduria@ice.go.cr",
            "direccion": "Sabana Norte, San José",
            "sitio_web": "https://www.grupoice.com",
            "nivel_importancia": "alto",
            "is_active": True
        },
        {
            "nombre_cliente": "Caja Costarricense de Seguro Social",
            "tipo_cliente": "publico",
            "identificacion": "4-000-042146",
            "sector_industria": "Salud",
            "telefono_principal": "2539-0000",
            "email_principal": "logistica@ccss.sa.cr",
            "direccion": "San José, Costa Rica",
            "sitio_web": "https://www.ccss.sa.cr",
            "nivel_importancia": "alto",
            "is_active": True
        },
        {
            "nombre_cliente": "Banco Nacional de Costa Rica",
            "tipo_cliente": "publico",
            "identificacion": "4-000-042128",
            "sector_industria": "Finanzas",
            "telefono_principal": "2212-2000",
            "email_principal": "compras@bncr.fi.cr",
            "direccion": "Avenida 1, San José",
            "sitio_web": "https://www.bncr.fi.cr",
            "nivel_importancia": "medio",
            "is_active": True
        },
        {
            "nombre_cliente": "Corporación XYZ S.A.",
            "tipo_cliente": "privado",
            "identificacion": "3-101-234567",
            "sector_industria": "Manufactura",
            "telefono_principal": "2290-5000",
            "email_principal": "procurement@xyz.com",
            "direccion": "Heredia, Costa Rica",
            "sitio_web": "https://www.xyz.com",
            "nivel_importancia": "medio",
            "is_active": True
        }
    ]

    created_clientes = []
    for cliente_data in clientes:
        cliente = Cliente(**cliente_data, created_by=1)
        db.add(cliente)
        created_clientes.append(cliente)

    db.commit()
    for cliente in created_clientes:
        db.refresh(cliente)

    print(f"✓ Created {len(created_clientes)} clientes")
    return created_clientes


def create_sample_contactos(db: SessionLocal, clientes: list):
    """Create sample contactos for clientes."""
    print("\nCreating sample contactos...")

    contactos_data = [
        # MEP
        {"cliente_id": clientes[0].cliente_id, "nombre_contacto": "Ana María Rodríguez",
         "cargo": "Directora de Compras", "email": "arodriguez@mep.go.cr",
         "telefono": "2222-1111 ext. 101", "nivel_decision": "alto", "es_contacto_principal": True},

        # ICE
        {"cliente_id": clientes[1].cliente_id, "nombre_contacto": "Carlos Hernández",
         "cargo": "Gerente de Adquisiciones", "email": "chernandez@ice.go.cr",
         "telefono": "2000-7001", "nivel_decision": "alto", "es_contacto_principal": True},

        # CCSS
        {"cliente_id": clientes[2].cliente_id, "nombre_contacto": "María Solís",
         "cargo": "Jefa de Logística", "email": "msolis@ccss.sa.cr",
         "telefono": "2539-0100", "nivel_decision": "alto", "es_contacto_principal": True},

        # BNCR
        {"cliente_id": clientes[3].cliente_id, "nombre_contacto": "Juan Pérez",
         "cargo": "Coordinador de Compras", "email": "jperez@bncr.fi.cr",
         "telefono": "2212-2100", "nivel_decision": "medio", "es_contacto_principal": True},

        # XYZ
        {"cliente_id": clientes[4].cliente_id, "nombre_contacto": "Laura Martínez",
         "cargo": "Procurement Manager", "email": "lmartinez@xyz.com",
         "telefono": "2290-5001", "nivel_decision": "alto", "es_contacto_principal": True},
    ]

    created_contactos = []
    for contacto_data in contactos_data:
        contacto = Contacto(**contacto_data, is_active=True, created_by=1)
        db.add(contacto)
        created_contactos.append(contacto)

    db.commit()
    print(f"✓ Created {len(created_contactos)} contactos")
    return created_contactos


def create_sample_licitaciones(db: SessionLocal, clientes: list):
    """Create sample licitaciones in various states."""
    print("\nCreating sample licitaciones...")

    today = date.today()

    licitaciones = [
        # Próxima a presentar (ALERTA)
        {
            "numero_licitacion": "2025-LIC-001-MEP",
            "cliente_id": clientes[0].cliente_id,
            "titulo_licitacion": "Adquisición de Equipos de Cómputo para Centros Educativos",
            "descripcion": "Compra de 500 computadoras portátiles para escuelas públicas",
            "estado_licitacion": "publicada",
            "categoria": "tecnologia",
            "fecha_publicacion": today - timedelta(days=20),
            "fecha_presentacion": today + timedelta(days=3),  # ALERTA: 3 días
            "monto_estimado": Decimal("250000000.00"),
            "monto_ofertado": Decimal("248500000.00"),
            "garantia_participacion": Decimal("5000000.00"),
            "fecha_vencimiento_garantia": today + timedelta(days=90),
            "probabilidad_exito": 75,
            "created_by": 1
        },
        # En ejecución, próxima a finalizar (ALERTA)
        {
            "numero_licitacion": "2024-LIC-089-ICE",
            "cliente_id": clientes[1].cliente_id,
            "titulo_licitacion": "Servicios de Mantenimiento Preventivo Subestaciones",
            "descripcion": "Mantenimiento de subestaciones eléctricas zona norte",
            "estado_licitacion": "en_ejecucion",
            "categoria": "servicios",
            "fecha_publicacion": today - timedelta(days=180),
            "fecha_presentacion": today - timedelta(days=150),
            "fecha_adjudicacion": today - timedelta(days=120),
            "fecha_inicio_contrato": today - timedelta(days=100),
            "fecha_fin_contrato": today + timedelta(days=20),  # ALERTA: 20 días
            "monto_estimado": Decimal("150000000.00"),
            "monto_adjudicado": Decimal("148000000.00"),
            "garantia_cumplimiento": Decimal("7400000.00"),
            "fecha_vencimiento_garantia": today + timedelta(days=10),  # ALERTA: 10 días
            "probabilidad_exito": 100,
            "created_by": 1
        },
        # Adjudicada recientemente
        {
            "numero_licitacion": "2025-LIC-005-CCSS",
            "cliente_id": clientes[2].cliente_id,
            "titulo_licitacion": "Suministro de Insumos Médicos",
            "descripcion": "Provisión de material médico quirúrgico",
            "estado_licitacion": "adjudicada",
            "categoria": "suministros",
            "fecha_publicacion": today - timedelta(days=45),
            "fecha_presentacion": today - timedelta(days=30),
            "fecha_adjudicacion": today - timedelta(days=5),
            "monto_estimado": Decimal("85000000.00"),
            "monto_adjudicado": Decimal("83500000.00"),
            "garantia_cumplimiento": Decimal("4175000.00"),
            "fecha_vencimiento_garantia": today + timedelta(days=180),
            "probabilidad_exito": 100,
            "created_by": 1
        },
        # En preparación
        {
            "numero_licitacion": "2025-LIC-012-BNCR",
            "cliente_id": clientes[3].cliente_id,
            "titulo_licitacion": "Consultoría para Implementación Sistema Core Bancario",
            "descripcion": "Servicios de consultoría especializada en banca",
            "estado_licitacion": "en_preparacion",
            "categoria": "consultoria",
            "fecha_publicacion": today + timedelta(days=15),
            "fecha_presentacion": today + timedelta(days=45),
            "monto_estimado": Decimal("320000000.00"),
            "probabilidad_exito": 60,
            "created_by": 1
        },
        # Privada - En presentación
        {
            "numero_licitacion": "2025-RFP-003-XYZ",
            "cliente_id": clientes[4].cliente_id,
            "titulo_licitacion": "Desarrollo de Sistema ERP Personalizado",
            "descripcion": "Desarrollo e implementación de ERP",
            "estado_licitacion": "publicada",
            "categoria": "desarrollo",
            "fecha_publicacion": today - timedelta(days=10),
            "fecha_presentacion": today + timedelta(days=20),
            "monto_estimado": Decimal("180000000.00"),
            "monto_ofertado": Decimal("175000000.00"),
            "probabilidad_exito": 70,
            "created_by": 1
        }
    ]

    created_licitaciones = []
    for lic_data in licitaciones:
        licitacion = Licitacion(**lic_data)
        db.add(licitacion)
        created_licitaciones.append(licitacion)

    db.commit()
    for lic in created_licitaciones:
        db.refresh(lic)

    print(f"✓ Created {len(created_licitaciones)} licitaciones")
    return created_licitaciones


def create_sample_documentos(db: SessionLocal, licitaciones: list):
    """Create sample documentos."""
    print("\nCreating sample documentos...")

    today = date.today()

    documentos = [
        # Licitación 1 - Documento próximo a vencer (ALERTA)
        {
            "licitacion_id": licitaciones[0].licitacion_id,
            "nombre_documento": "Certificación Vigencia Fiscal",
            "tipo_documento": "certificacion",
            "estado_documento": "activo",
            "fecha_vencimiento": today + timedelta(days=10),  # ALERTA: 10 días
            "es_confidencial": False,
            "version": 1,
            "created_by": 1
        },
        # Licitación 2 - Documento vencido (ALERTA)
        {
            "licitacion_id": licitaciones[1].licitacion_id,
            "nombre_documento": "Póliza de Riesgos del Trabajo",
            "tipo_documento": "poliza",
            "estado_documento": "activo",
            "fecha_vencimiento": today - timedelta(days=5),  # ALERTA: Vencido
            "es_confidencial": False,
            "version": 1,
            "created_by": 1
        },
        # Licitación 1 - Oferta técnica
        {
            "licitacion_id": licitaciones[0].licitacion_id,
            "nombre_documento": "Oferta Técnica MEP 2025-001",
            "tipo_documento": "oferta_tecnica",
            "estado_documento": "activo",
            "es_confidencial": True,
            "tags": ["oferta", "tecnica", "computadoras"],
            "version": 2,
            "version_anterior_id": None,
            "created_by": 1
        },
        # Licitación 2 - Contrato
        {
            "licitacion_id": licitaciones[1].licitacion_id,
            "nombre_documento": "Contrato ICE Mantenimiento",
            "tipo_documento": "contrato",
            "estado_documento": "activo",
            "es_confidencial": True,
            "version": 1,
            "created_by": 1
        }
    ]

    created_documentos = []
    for doc_data in documentos:
        documento = Documento(**doc_data)
        db.add(documento)
        created_documentos.append(documento)

    db.commit()
    print(f"✓ Created {len(created_documentos)} documentos")
    return created_documentos


def create_sample_interacciones(db: SessionLocal, clientes: list, contactos: list):
    """Create sample CRM interactions."""
    print("\nCreating sample interacciones...")

    today = date.today()
    now = datetime.now()

    interacciones = [
        # Seguimiento próximo (ALERTA)
        {
            "cliente_id": clientes[0].cliente_id,
            "contacto_id": contactos[0].contacto_id,
            "tipo_interaccion": "reunion",
            "fecha_interaccion": now - timedelta(days=20),
            "descripcion": "Reunión de seguimiento sobre licitación de computadoras",
            "resultado": "Positivo, requieren ajustes menores en especificaciones",
            "requiere_seguimiento": True,
            "fecha_seguimiento": today + timedelta(days=2),  # ALERTA: 2 días
            "proximos_pasos": "Enviar propuesta ajustada con nuevas especificaciones",
            "participantes": ["Ana María Rodríguez", "Equipo Técnico MEP"],
            "created_by": 1
        },
        # Seguimiento atrasado (ALERTA)
        {
            "cliente_id": clientes[1].cliente_id,
            "contacto_id": contactos[1].contacto_id,
            "tipo_interaccion": "llamada",
            "fecha_interaccion": now - timedelta(days=15),
            "descripcion": "Llamada de coordinación para inicio de contrato",
            "resultado": "Pendiente definir cronograma de mantenimientos",
            "requiere_seguimiento": True,
            "fecha_seguimiento": today - timedelta(days=3),  # ALERTA: Atrasado
            "proximos_pasos": "Coordinar reunión para definir cronograma",
            "created_by": 1
        },
        # Interacción reciente sin seguimiento
        {
            "cliente_id": clientes[2].cliente_id,
            "contacto_id": contactos[2].contacto_id,
            "tipo_interaccion": "email",
            "fecha_interaccion": now - timedelta(days=2),
            "descripcion": "Envío de documentación post-adjudicación",
            "resultado": "Documentos recibidos y aceptados",
            "requiere_seguimiento": False,
            "created_by": 1
        }
    ]

    created_interacciones = []
    for int_data in interacciones:
        interaccion = InteraccionCliente(**int_data)
        db.add(interaccion)
        created_interacciones.append(interaccion)

    db.commit()
    print(f"✓ Created {len(created_interacciones)} interacciones")
    return created_interacciones


def create_sample_ampliaciones(db: SessionLocal, licitaciones: list):
    """Create sample ampliaciones."""
    print("\nCreating sample ampliaciones...")

    today = date.today()

    # Ampliación pendiente (ALERTA)
    ampliacion = Ampliacion(
        licitacion_id=licitaciones[1].licitacion_id,  # ICE contrato
        tipo_ampliacion="monto",
        descripcion="Ampliación por trabajos adicionales no contemplados",
        justificacion="Se requieren trabajos adicionales en 2 subestaciones más",
        fecha_anterior_fin=licitaciones[1].fecha_fin_contrato,
        fecha_nueva_fin=licitaciones[1].fecha_fin_contrato + timedelta(days=60),
        monto_anterior=licitaciones[1].monto_adjudicado,
        monto_nuevo=licitaciones[1].monto_adjudicado + Decimal("25000000.00"),
        monto_ampliacion=Decimal("25000000.00"),
        estado_ampliacion="pendiente",
        created_by=1,
        created_at=datetime.now() - timedelta(days=5)  # Pendiente 5 días (ALERTA si > 3)
    )
    db.add(ampliacion)

    db.commit()
    print("✓ Created 1 ampliación pendiente")


def create_user_configurations(db: SessionLocal):
    """Create alert configurations for users."""
    print("\nCreating user alert configurations...")

    # Admin user (user_id=1) configuration
    config = ConfiguracionAlertas(
        user_id=1,
        alertas_documentos_vencidos=True,
        dias_alerta_documentos=15,
        alertas_licitaciones_proximas=True,
        dias_alerta_licitaciones=7,
        alertas_contratos_proximos=True,
        dias_alerta_contratos=30,
        alertas_garantias=True,
        dias_alerta_garantias=15,
        notificar_email=True,
        notificar_push=True,
        enviar_resumen_diario=True,
        hora_envio_resumen=8
    )
    db.add(config)

    db.commit()
    print("✓ Created user configurations")


def main():
    """Main seed function."""
    parser = argparse.ArgumentParser(description="Seed database with sample data")
    parser.add_argument('--clear', action='store_true', help='Clear existing data first')
    args = parser.parse_args()

    print("=" * 60)
    print("SEEDING DATABASE WITH SAMPLE DATA")
    print("=" * 60)

    db = SessionLocal()

    try:
        if args.clear:
            clear_data(db)

        # Create data in order
        clientes = create_sample_clientes(db)
        contactos = create_sample_contactos(db, clientes)
        licitaciones = create_sample_licitaciones(db, clientes)
        documentos = create_sample_documentos(db, licitaciones)
        interacciones = create_sample_interacciones(db, clientes, contactos)
        create_sample_ampliaciones(db, licitaciones)
        create_user_configurations(db)

        print("\n" + "=" * 60)
        print("✓ DATABASE SEEDED SUCCESSFULLY")
        print("=" * 60)
        print("\nSample data includes:")
        print(f"  - {len(clientes)} clientes (MEP, ICE, CCSS, BNCR, XYZ)")
        print(f"  - {len(contactos)} contactos principales")
        print(f"  - {len(licitaciones)} licitaciones en diversos estados")
        print(f"  - {len(documentos)} documentos (algunos próximos a vencer)")
        print(f"  - {len(interacciones)} interacciones CRM (con seguimientos)")
        print(f"  - 1 ampliación pendiente de aprobación")
        print(f"  - Configuraciones de alertas para usuarios")
        print("\n⚠️  DATA WITH ALERTS:")
        print("  - Documento vence en 10 días")
        print("  - Documento vencido hace 5 días")
        print("  - Licitación vence en 3 días")
        print("  - Contrato finaliza en 20 días")
        print("  - Garantía vence en 10 días")
        print("  - Seguimiento CRM en 2 días")
        print("  - Seguimiento CRM atrasado 3 días")
        print("  - Ampliación pendiente hace 5 días")
        print("\n💡 Run the alert worker to generate alerts:")
        print("  python run_worker.py --once")

    except Exception as e:
        print(f"\n❌ Error seeding database: {str(e)}")
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()


if __name__ == "__main__":
    main()
