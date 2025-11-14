# FASE 7: Reportes y Analytics 📊

**Duración**: Sprint 11-12 (2 semanas)

## 🎯 Objetivos
- ✅ Dashboard con KPIs del negocio
- ✅ Reportes estadísticos avanzados
- ✅ Gráficas y visualizaciones
- ✅ Exportación de datos (PDF, Excel)
- ✅ Análisis de tendencias

## 💻 Backend - Endpoints de Reportes

**app/api/v1/endpoints/reportes.py**
```python
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, extract
from datetime import date, datetime, timedelta
from typing import Optional

from app.database import get_db
from app.models.licitacion import Licitacion
from app.models.documento import Documento
from app.models.ampliacion import Ampliacion
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/dashboard")
def get_dashboard_stats(
    fecha_desde: Optional[date] = None,
    fecha_hasta: Optional[date] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Obtener estadísticas generales del dashboard"""
    
    # Filtros de fecha
    if not fecha_desde:
        fecha_desde = date.today() - timedelta(days=365)
    if not fecha_hasta:
        fecha_hasta = date.today()
    
    # Total de licitaciones
    total_licitaciones = db.query(Licitacion).filter(
        Licitacion.is_active == True
    ).count()
    
    # Licitaciones por estado
    licitaciones_por_estado = db.query(
        Licitacion.estado_licitacion,
        func.count(Licitacion.licitacion_id).label('count')
    ).filter(
        Licitacion.is_active == True
    ).group_by(Licitacion.estado_licitacion).all()
    
    # Tasa de éxito
    presentadas = db.query(Licitacion).filter(
        Licitacion.estado_licitacion.in_(['presentada', 'adjudicada', 'en_ejecucion', 'finalizada'])
    ).count()
    
    adjudicadas = db.query(Licitacion).filter(
        Licitacion.estado_licitacion.in_(['adjudicada', 'en_ejecucion', 'finalizada'])
    ).count()
    
    tasa_exito = (adjudicadas / presentadas * 100) if presentadas > 0 else 0
    
    # Monto total adjudicado
    monto_total = db.query(
        func.sum(Licitacion.monto_adjudicado)
    ).filter(
        Licitacion.estado_licitacion.in_(['adjudicada', 'en_ejecucion', 'finalizada']),
        Licitacion.fecha_adjudicacion.between(fecha_desde, fecha_hasta)
    ).scalar() or 0
    
    # Documentos por vencer (próximos 30 días)
    documentos_por_vencer = db.query(Documento).filter(
        Documento.fecha_vencimiento.between(
            date.today(),
            date.today() + timedelta(days=30)
        ),
        Documento.estado_documento == 'activo'
    ).count()
    
    # Licitaciones activas
    licitaciones_activas = db.query(Licitacion).filter(
        Licitacion.estado_licitacion == 'en_ejecucion'
    ).count()
    
    return {
        "totales": {
            "total_licitaciones": total_licitaciones,
            "licitaciones_activas": licitaciones_activas,
            "tasa_exito": round(tasa_exito, 2),
            "monto_total_adjudicado": float(monto_total),
            "documentos_por_vencer": documentos_por_vencer
        },
        "licitaciones_por_estado": [
            {"estado": row[0], "cantidad": row[1]} 
            for row in licitaciones_por_estado
        ],
        "periodo": {
            "desde": fecha_desde.isoformat(),
            "hasta": fecha_hasta.isoformat()
        }
    }

@router.get("/licitaciones-por-mes")
def get_licitaciones_por_mes(
    anio: int = Query(default=datetime.now().year),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Licitaciones agrupadas por mes"""
    
    licitaciones_mes = db.query(
        extract('month', Licitacion.fecha_presentacion).label('mes'),
        func.count(Licitacion.licitacion_id).label('total'),
        func.count(
            case([(Licitacion.estado_licitacion == 'adjudicada', 1)])
        ).label('adjudicadas')
    ).filter(
        extract('year', Licitacion.fecha_presentacion) == anio
    ).group_by('mes').all()
    
    meses = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ]
    
    resultado = []
    for i in range(1, 13):
        data = next((r for r in licitaciones_mes if r[0] == i), None)
        resultado.append({
            "mes": meses[i-1],
            "mes_num": i,
            "total": data[1] if data else 0,
            "adjudicadas": data[2] if data else 0
        })
    
    return resultado

@router.get("/licitaciones-por-categoria")
def get_licitaciones_por_categoria(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Licitaciones agrupadas por categoría"""
    
    result = db.query(
        Licitacion.categoria,
        func.count(Licitacion.licitacion_id).label('cantidad'),
        func.sum(Licitacion.monto_adjudicado).label('monto_total')
    ).filter(
        Licitacion.is_active == True
    ).group_by(Licitacion.categoria).all()
    
    return [
        {
            "categoria": row[0] or "Sin categoría",
            "cantidad": row[1],
            "monto_total": float(row[2] or 0)
        }
        for row in result
    ]

@router.get("/top-clientes")
def get_top_clientes(
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Top clientes por monto adjudicado"""
    
    from app.models.cliente import Cliente
    
    result = db.query(
        Cliente.nombre_cliente,
        func.count(Licitacion.licitacion_id).label('total_licitaciones'),
        func.sum(Licitacion.monto_adjudicado).label('monto_total')
    ).join(
        Licitacion, Cliente.cliente_id == Licitacion.cliente_id
    ).filter(
        Licitacion.estado_licitacion.in_(['adjudicada', 'en_ejecucion', 'finalizada'])
    ).group_by(
        Cliente.nombre_cliente
    ).order_by(
        func.sum(Licitacion.monto_adjudicado).desc()
    ).limit(limit).all()
    
    return [
        {
            "cliente": row[0],
            "total_licitaciones": row[1],
            "monto_total": float(row[2] or 0)
        }
        for row in result
    ]

@router.get("/tiempo-promedio-adjudicacion")
def get_tiempo_promedio_adjudicacion(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Tiempo promedio entre presentación y adjudicación"""
    
    licitaciones = db.query(Licitacion).filter(
        Licitacion.fecha_presentacion.isnot(None),
        Licitacion.fecha_adjudicacion.isnot(None),
        Licitacion.estado_licitacion.in_(['adjudicada', 'en_ejecucion', 'finalizada'])
    ).all()
    
    if not licitaciones:
        return {"dias_promedio": 0, "total_licitaciones": 0}
    
    total_dias = sum(
        (lic.fecha_adjudicacion - lic.fecha_presentacion).days
        for lic in licitaciones
    )
    
    return {
        "dias_promedio": round(total_dias / len(licitaciones), 1),
        "total_licitaciones": len(licitaciones)
    }

@router.get("/proximo-vencimientos")
def get_proximos_vencimientos(
    dias: int = Query(30, ge=1, le=90),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Contratos y documentos próximos a vencer"""
    
    fecha_limite = date.today() + timedelta(days=dias)
    
    # Contratos próximos a finalizar
    contratos = db.query(Licitacion).filter(
        Licitacion.fecha_fin_contrato.between(date.today(), fecha_limite),
        Licitacion.estado_licitacion == 'en_ejecucion'
    ).all()
    
    # Documentos próximos a vencer
    documentos = db.query(Documento).filter(
        Documento.fecha_vencimiento.between(date.today(), fecha_limite),
        Documento.estado_documento == 'activo'
    ).all()
    
    return {
        "contratos": [
            {
                "licitacion_id": c.licitacion_id,
                "numero": c.numero_licitacion,
                "nombre": c.nombre_licitacion,
                "fecha_fin": c.fecha_fin_contrato.isoformat(),
                "dias_restantes": (c.fecha_fin_contrato - date.today()).days
            }
            for c in contratos
        ],
        "documentos": [
            {
                "documento_id": d.documento_id,
                "nombre": d.nombre_documento,
                "tipo": d.tipo_documento,
                "fecha_vencimiento": d.fecha_vencimiento.isoformat(),
                "dias_restantes": (d.fecha_vencimiento - date.today()).days
            }
            for d in documentos
        ]
    }

@router.post("/exportar-excel")
async def exportar_reporte_excel(
    tipo_reporte: str,
    fecha_desde: Optional[date] = None,
    fecha_hasta: Optional[date] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Exportar reporte a Excel"""
    import pandas as pd
    from io import BytesIO
    from fastapi.responses import StreamingResponse
    
    # Obtener datos según tipo de reporte
    if tipo_reporte == "licitaciones":
        licitaciones = db.query(Licitacion).filter(Licitacion.is_active == True).all()
        data = [
            {
                "Número": l.numero_licitacion,
                "Nombre": l.nombre_licitacion,
                "Cliente": l.cliente.nombre_cliente if l.cliente else "",
                "Estado": l.estado_licitacion,
                "Monto Ofertado": l.monto_ofertado,
                "Monto Adjudicado": l.monto_adjudicado,
                "Fecha Presentación": l.fecha_presentacion
            }
            for l in licitaciones
        ]
    
    # Crear DataFrame y exportar
    df = pd.DataFrame(data)
    output = BytesIO()
    with pd.ExcelWriter(output, engine='openpyxl') as writer:
        df.to_excel(writer, index=False, sheet_name='Reporte')
    output.seek(0)
    
    return StreamingResponse(
        output,
        media_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        headers={"Content-Disposition": f"attachment; filename=reporte_{tipo_reporte}.xlsx"}
    )
```

## 📱 Frontend - Dashboard con Gráficas

**lib/presentation/screens/reportes/dashboard_screen.dart**
```dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // KPIs principales
            Row(
              children: [
                Expanded(child: _KPICard(
                  title: 'Licitaciones',
                  value: '127',
                  subtitle: 'Total',
                  icon: Icons.description,
                  color: Colors.blue,
                )),
                SizedBox(width: 16),
                Expanded(child: _KPICard(
                  title: 'Tasa Éxito',
                  value: '68%',
                  subtitle: 'Adjudicadas',
                  icon: Icons.check_circle,
                  color: Colors.green,
                )),
              ],
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _KPICard(
                  title: 'Monto Total',
                  value: '₡450M',
                  subtitle: 'Adjudicado',
                  icon: Icons.attach_money,
                  color: Colors.orange,
                )),
                SizedBox(width: 16),
                Expanded(child: _KPICard(
                  title: 'Alertas',
                  value: '15',
                  subtitle: 'Pendientes',
                  icon: Icons.warning,
                  color: Colors.red,
                )),
              ],
            ),
            SizedBox(height: 24),
            
            // Gráfica de licitaciones por mes
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Licitaciones por Mes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(show: true),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                FlSpot(0, 3),
                                FlSpot(1, 5),
                                FlSpot(2, 4),
                                FlSpot(3, 7),
                                FlSpot(4, 6),
                                FlSpot(5, 8),
                              ],
                              isCurved: true,
                              color: Colors.blue,
                              dotData: FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Gráfica de pastel - Por categoría
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Por Categoría',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: 40,
                              title: 'Servicios',
                              color: Colors.blue,
                            ),
                            PieChartSectionData(
                              value: 30,
                              title: 'Obras',
                              color: Colors.green,
                            ),
                            PieChartSectionData(
                              value: 20,
                              title: 'Bienes',
                              color: Colors.orange,
                            ),
                            PieChartSectionData(
                              value: 10,
                              title: 'Consultoría',
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  
  const _KPICard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

# FASE 8: Auditoría y Refinamiento 🔍

**Duración**: Sprint 13-14 (2 semanas)

## 🎯 Objetivos
- ✅ Sistema de logs y auditoría
- ✅ Trazabilidad completa de acciones
- ✅ Testing exhaustivo
- ✅ Optimización de performance
- ✅ Documentación final

## 🗄️ Base de Datos - Sistema de Auditoría

```sql
CREATE TABLE auditoria (
    auditoria_id SERIAL PRIMARY KEY,
    
    -- Usuario y sesión
    user_id INTEGER REFERENCES users(user_id) NOT NULL,
    username VARCHAR(100) NOT NULL,
    session_id VARCHAR(100),
    
    -- Acción realizada
    accion VARCHAR(100) NOT NULL,
    -- Acciones: create, update, delete, login, logout, download, upload
    
    tabla_afectada VARCHAR(100),
    registro_id INTEGER,
    
    -- Datos de la acción
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    
    -- Contexto
    metodo_http VARCHAR(10),
    endpoint VARCHAR(255),
    ip_address VARCHAR(50),
    user_agent TEXT,
    
    -- Resultado
    exitoso BOOLEAN DEFAULT TRUE,
    mensaje_error TEXT,
    
    -- Timestamp
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Índices para búsqueda rápida
    CONSTRAINT idx_auditoria_compuesto
        CHECK (tabla_afectada IS NOT NULL OR accion IN ('login', 'logout'))
);

CREATE INDEX idx_auditoria_user ON auditoria(user_id);
CREATE INDEX idx_auditoria_tabla ON auditoria(tabla_afectada, registro_id);
CREATE INDEX idx_auditoria_fecha ON auditoria(timestamp);
CREATE INDEX idx_auditoria_accion ON auditoria(accion);
```

## 💻 Backend - Middleware de Auditoría

**app/middleware/audit_middleware.py**
```python
from fastapi import Request
from sqlalchemy.orm import Session
from datetime import datetime
import json

from app.models.auditoria import Auditoria
from app.database import SessionLocal

class AuditMiddleware:
    
    @staticmethod
    async def log_action(
        user_id: int,
        username: str,
        accion: str,
        tabla_afectada: str = None,
        registro_id: int = None,
        datos_anteriores: dict = None,
        datos_nuevos: dict = None,
        request: Request = None,
        exitoso: bool = True,
        mensaje_error: str = None
    ):
        """Registrar acción en auditoría"""
        
        db = SessionLocal()
        try:
            audit_log = Auditoria(
                user_id=user_id,
                username=username,
                accion=accion,
                tabla_afectada=tabla_afectada,
                registro_id=registro_id,
                datos_anteriores=datos_anteriores,
                datos_nuevos=datos_nuevos,
                metodo_http=request.method if request else None,
                endpoint=str(request.url.path) if request else None,
                ip_address=request.client.host if request else None,
                user_agent=request.headers.get('user-agent') if request else None,
                exitoso=exitoso,
                mensaje_error=mensaje_error,
                timestamp=datetime.now()
            )
            
            db.add(audit_log)
            db.commit()
        except Exception as e:
            print(f"Error registrando auditoría: {e}")
        finally:
            db.close()
    
    @staticmethod
    def log_login(user_id: int, username: str, request: Request, exitoso: bool = True):
        """Registrar inicio de sesión"""
        AuditMiddleware.log_action(
            user_id=user_id,
            username=username,
            accion='login',
            request=request,
            exitoso=exitoso
        )
    
    @staticmethod
    def log_create(user_id: int, username: str, tabla: str, registro_id: int, datos: dict, request: Request = None):
        """Registrar creación de registro"""
        AuditMiddleware.log_action(
            user_id=user_id,
            username=username,
            accion='create',
            tabla_afectada=tabla,
            registro_id=registro_id,
            datos_nuevos=datos,
            request=request
        )
    
    @staticmethod
    def log_update(user_id: int, username: str, tabla: str, registro_id: int, 
                   datos_anteriores: dict, datos_nuevos: dict, request: Request = None):
        """Registrar actualización de registro"""
        AuditMiddleware.log_action(
            user_id=user_id,
            username=username,
            accion='update',
            tabla_afectada=tabla,
            registro_id=registro_id,
            datos_anteriores=datos_anteriores,
            datos_nuevos=datos_nuevos,
            request=request
        )
    
    @staticmethod
    def log_delete(user_id: int, username: str, tabla: str, registro_id: int, request: Request = None):
        """Registrar eliminación de registro"""
        AuditMiddleware.log_action(
            user_id=user_id,
            username=username,
            accion='delete',
            tabla_afectada=tabla,
            registro_id=registro_id,
            request=request
        )
```

**Uso en endpoints:**
```python
@router.post("/", response_model=LicitacionResponse, status_code=201)
def create_licitacion(
    licitacion_data: LicitacionCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Crear nueva licitación"""
    licitacion = LicitacionService.create_licitacion(db, licitacion_data, current_user.user_id)
    
    # Registrar en auditoría
    AuditMiddleware.log_create(
        user_id=current_user.user_id,
        username=current_user.username,
        tabla='licitaciones',
        registro_id=licitacion.licitacion_id,
        datos=licitacion_data.model_dump(),
        request=request
    )
    
    return licitacion
```

## 📱 Frontend - Pantalla de Auditoría

```dart
class AuditoriaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Auditoría'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilters(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: 20,
        itemBuilder: (context, index) {
          return _AuditLogItem();
        },
      ),
    );
  }
}

class _AuditLogItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(Icons.edit, color: Colors.blue),
        ),
        title: Text(
          'Licitación actualizada',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Por: Juan Pérez'),
            Text(
              '15/11/2025 10:30 AM',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cambios realizados:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                _ChangeItem(
                  field: 'Estado',
                  oldValue: 'En evaluación',
                  newValue: 'Adjudicada',
                ),
                _ChangeItem(
                  field: 'Monto adjudicado',
                  oldValue: '-',
                  newValue: '₡50,000,000.00',
                ),
                Divider(),
                Text(
                  'IP: 192.168.1.100',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeItem extends StatelessWidget {
  final String field;
  final String oldValue;
  final String newValue;
  
  const _ChangeItem({
    required this.field,
    required this.oldValue,
    required this.newValue,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$field: ', style: TextStyle(fontWeight: FontWeight.w500)),
          Text(
            oldValue,
            style: TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Colors.red,
            ),
          ),
          Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          Text(
            newValue,
            style: TextStyle(color: Colors.green),
          ),
        ],
      ),
    );
  }
}
```

## 🧪 Testing Completo

**tests/test_integration.py**
```python
import pytest
from fastapi.testclient import TestClient

def test_flujo_completo_licitacion(client, auth_token):
    """Test de flujo completo: crear, editar, documentos, ampliaciones"""
    
    # 1. Crear cliente
    cliente_response = client.post(
        "/api/v1/clientes/",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "nombre_cliente": "Cliente Test",
            "tipo_cliente": "publico"
        }
    )
    assert cliente_response.status_code == 201
    cliente_id = cliente_response.json()["cliente_id"]
    
    # 2. Crear licitación
    lic_response = client.post(
        "/api/v1/licitaciones/",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "numero_licitacion": "TEST-001",
            "nombre_licitacion": "Licitación de Prueba",
            "cliente_id": cliente_id,
            "estado_licitacion": "en_preparacion"
        }
    )
    assert lic_response.status_code == 201
    lic_id = lic_response.json()["licitacion_id"]
    
    # 3. Subir documento
    # ... (test de upload)
    
    # 4. Crear ampliación
    amp_response = client.post(
        "/api/v1/ampliaciones/",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "licitacion_id": lic_id,
            "tipo_ampliacion": "ampliacion_plazo",
            "descripcion": "Ampliación de prueba",
            "dias_ampliados": 30,
            "fecha_solicitud": "2025-01-15"
        }
    )
    assert amp_response.status_code == 201
    
    # 5. Verificar dashboard stats
    stats_response = client.get(
        "/api/v1/reportes/dashboard",
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert stats_response.status_code == 200
    assert stats_response.json()["totales"]["total_licitaciones"] > 0
```

## 🚀 Optimización de Performance

**app/core/cache.py**
```python
from functools import wraps
from datetime import datetime, timedelta
import json

# Cache simple en memoria (usar Redis en producción)
_cache = {}

def cache_response(expire_seconds: int = 300):
    """Decorador para cachear respuestas de endpoints"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Generar key del cache
            cache_key = f"{func.__name__}:{str(args)}:{str(kwargs)}"
            
            # Verificar si existe en cache y no ha expirado
            if cache_key in _cache:
                cached_data, expiry = _cache[cache_key]
                if datetime.now() < expiry:
                    return cached_data
            
            # Ejecutar función y guardar en cache
            result = await func(*args, **kwargs)
            _cache[cache_key] = (result, datetime.now() + timedelta(seconds=expire_seconds))
            return result
        
        return wrapper
    return decorator

# Uso en endpoints:
@router.get("/dashboard")
@cache_response(expire_seconds=300)  # Cache por 5 minutos
async def get_dashboard_stats(...):
    # ...
    pass
```

**Índices adicionales para optimización:**
```sql
-- Índices compuestos para queries frecuentes
CREATE INDEX idx_licitaciones_estado_fecha ON licitaciones(estado_licitacion, fecha_presentacion DESC);
CREATE INDEX idx_documentos_vencimiento_activo ON documentos(fecha_vencimiento, estado_documento) WHERE is_active = TRUE;
CREATE INDEX idx_alertas_user_estado ON alertas(user_id, estado_alerta, fecha_alerta DESC);

-- Índice para búsqueda de texto completo
CREATE INDEX idx_licitaciones_search ON licitaciones 
USING GIN (to_tsvector('spanish', nombre_licitacion || ' ' || COALESCE(descripcion, '')));
```

## 📝 Documentación Final

**README.md del proyecto**
```markdown
# Sistema de Gestión de Licitaciones

## 🚀 Características

### Módulos Implementados
1. **Autenticación y Usuarios** - JWT, roles, permisos
2. **Licitaciones** - CRUD completo con estados y workflow
3. **Gestión Documental** - Upload/download con control de vencimientos
4. **Ampliaciones y Prórrogas** - Historial de cambios
5. **CRM de Clientes** - Contactos e interacciones
6. **Sistema de Alertas** - Notificaciones automáticas
7. **Reportes y Analytics** - Dashboard con KPIs
8. **Auditoría** - Trazabilidad completa

## 📋 Requisitos

### Backend
- Python 3.9+
- PostgreSQL 12+
- Dependencias en `requirements.txt`

### Frontend
- Flutter 3.0+
- Dart 2.17+
- Dependencias en `pubspec.yaml`

## 🔧 Instalación

### Backend
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Editar .env con tus configuraciones
alembic upgrade head
uvicorn app.main:app --reload
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome  # Para web
flutter run  # Para móvil
```

## 🗄️ Base de Datos

### Crear base de datos
```bash
createdb licitaciones_db
```

### Ejecutar migraciones
```bash
alembic upgrade head
```

### Backup
```bash
pg_dump licitaciones_db > backup_$(date +%Y%m%d).sql
```

## 🔐 Seguridad

- Contraseñas hasheadas con bcrypt
- JWT con expiración configurable
- HTTPS obligatorio en producción
- Validación de archivos subidos
- Rate limiting en endpoints críticos
- Logs de auditoría completos

## 📊 API Endpoints

### Autenticación
- `POST /api/v1/auth/login` - Iniciar sesión
- `GET /api/v1/auth/me` - Usuario actual
- `POST /api/v1/auth/logout` - Cerrar sesión

### Licitaciones
- `GET /api/v1/licitaciones/` - Listar (con filtros)
- `POST /api/v1/licitaciones/` - Crear
- `GET /api/v1/licitaciones/{id}` - Obtener
- `PUT /api/v1/licitaciones/{id}` - Actualizar
- `DELETE /api/v1/licitaciones/{id}` - Eliminar

### Documentos
- `POST /api/v1/documentos/upload` - Subir
- `GET /api/v1/documentos/` - Listar
- `GET /api/v1/documentos/{id}/download` - Descargar
- `GET /api/v1/documentos/por-vencer` - Próximos a vencer

### Reportes
- `GET /api/v1/reportes/dashboard` - Estadísticas generales
- `GET /api/v1/reportes/licitaciones-por-mes` - Gráfica mensual
- `POST /api/v1/reportes/exportar-excel` - Exportar a Excel

## 🧪 Testing

```bash
# Backend
pytest tests/ -v --cov=app

# Frontend
flutter test
```

## 📦 Deployment

### Docker
```bash
docker-compose up -d
```

### Manual
1. Configurar servidor (Ubuntu 20.04+)
2. Instalar Nginx, PostgreSQL
3. Configurar SSL con Let's Encrypt
4. Usar supervisor para process management
5. Configurar backups automáticos

## 🔧 Mantenimiento

### Tareas Programadas
- **Diario 00:01**: Actualizar estados de documentos vencidos
- **Diario 08:00**: Generar alertas
- **Semanal**: Backup de base de datos
- **Mensual**: Limpieza de logs antiguos

### Monitoreo
- Logs en `/var/log/licitaciones/`
- Métricas en Prometheus (opcional)
- Alertas en Sentry (opcional)

## 📞 Soporte

Para reportar bugs o solicitar features:
- Email: soporte@empresa.com
- Issues: GitHub repository

## 📄 Licencia

Propietario - Todos los derechos reservados
```

## ✅ Checklist Final - FASE 8

### Auditoría
- [ ] Sistema de logs implementado
- [ ] Middleware de auditoría funcionando
- [ ] Registro de todas las acciones CRUD
- [ ] Logs de login/logout
- [ ] Pantalla de auditoría en frontend
- [ ] Búsqueda y filtrado de logs

### Testing
- [ ] Tests unitarios (>80% coverage)
- [ ] Tests de integración completos
- [ ] Tests end-to-end principales flujos
- [ ] Tests de seguridad
- [ ] Tests de performance
- [ ] Tests de carga (opcional)

### Performance
- [ ] Índices de base de datos optimizados
- [ ] Queries optimizadas (sin N+1)
- [ ] Cache implementado en endpoints críticos
- [ ] Paginación en todas las listas
- [ ] Lazy loading en frontend
- [ ] Compresión de respuestas API

### Documentación
- [ ] README completo
- [ ] Documentación API (Swagger)
- [ ] Guía de instalación
- [ ] Guía de deployment
- [ ] Documentación de arquitectura
- [ ] Manual de usuario (opcional)

### Seguridad
- [ ] Sanitización de inputs
- [ ] Protección CSRF
- [ ] Rate limiting
- [ ] Validación de archivos
- [ ] Secrets en variables de entorno
- [ ] HTTPS configurado
- [ ] Headers de seguridad

### UX/UI
- [ ] Diseño responsive
- [ ] Loading states
- [ ] Error handling amigable
- [ ] Confirmaciones en acciones críticas
- [ ] Tooltips y ayuda contextual
- [ ] Accesibilidad básica

### DevOps
- [ ] Docker configurado
- [ ] CI/CD pipeline (opcional)
- [ ] Monitoreo de logs
- [ ] Backups automáticos
- [ ] Estrategia de rollback
- [ ] Documentación de deployment

---

## 🎉 Entregables Finales

### Backend
```
backend/
├── app/
│   ├── api/v1/endpoints/  (8 archivos)
│   ├── models/            (8 modelos)
│   ├── schemas/           (8 schemas)
│   ├── services/          (5 services)
│   ├── workers/           (2 workers)
│   ├── middleware/        (1 audit middleware)
│   └── utils/             (3 utilidades)
├── tests/                 (15+ tests)
├── alembic/versions/      (migraciones)
├── requirements.txt
├── .env.example
├── Dockerfile
└── README.md
```

### Frontend
```
frontend/
├── lib/
│   ├── presentation/screens/  (15+ pantallas)
│   ├── data/
│   │   ├── models/           (6 modelos)
│   │   └── repositories/     (6 repositories)
│   ├── core/
│   │   ├── config/
│   │   └── theme/
│   └── widgets/              (10+ widgets)
├── test/
├── pubspec.yaml
└── README.md
```

### Base de Datos
- 9 tablas principales
- 1 vista
- 20+ índices optimizados
- Migraciones versionadas

### Documentación
- README general
- API documentation (Swagger)
- Guía de instalación
- Guía de deployment
- Diagramas de arquitectura

---

## 🎯 Métricas de Éxito

### Funcionales
- ✅ 100% de los módulos implementados
- ✅ CRUD completo en todos los módulos
- ✅ Sistema de alertas funcionando
- ✅ Reportes generándose correctamente
- ✅ Sistema de auditoría registrando todo

### Técnicas
- ✅ >80% test coverage
- ✅ API response time < 500ms (promedio)
- ✅ Cero errores críticos en producción
- ✅ 99% uptime

### UX
- ✅ Tiempo de carga < 3 segundos
- ✅ Mobile responsive
- ✅ Interfaz intuitiva
- ✅ Feedback claro al usuario

---

## 🔄 Próximas Iteraciones (Post-MVP)

### Fase 9 (Futuro)
- [ ] Notificaciones push móviles
- [ ] Integración con WhatsApp
- [ ] OCR para extracción de datos de documentos
- [ ] Firma digital de documentos
- [ ] App móvil nativa
- [ ] Integración con SICOP (Costa Rica)
- [ ] BI avanzado con Machine Learning
- [ ] API pública para integraciones

---

## 📝 Notas de Implementación

### Prioridades
1. **Fase 1-2**: Críticas - Base del sistema
2. **Fase 3-4**: Altas - Funcionalidad core
3. **Fase 5-6**: Medias - Mejoras significativas
4. **Fase 7-8**: Importantes - Análisis y calidad

### Stack Tecnológico Final
- **Backend**: FastAPI + PostgreSQL + SQLAlchemy + Alembic
- **Frontend**: Flutter + Riverpod + Dio
- **DevOps**: Docker + Nginx + PostgreSQL
- **Monitoring**: Logs + Auditoría interna

### Estimación Total
- **Tiempo**: 13-14 sprints (26-28 semanas)
- **Esfuerzo**: 1-2 desarrolladores full-stack
- **Complejidad**: Media-Alta

---

**✅ PROYECTO COMPLETO - TODAS LAS FASES DOCUMENTADAS**

¡Sistema listo para implementación! 🚀