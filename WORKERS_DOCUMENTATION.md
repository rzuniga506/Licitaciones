# Sistema de Workers y Alertas Automáticas

## Descripción General

El sistema de licitaciones incluye un **worker de fondo** que genera alertas automáticamente basándose en eventos del sistema. Este worker utiliza APScheduler para ejecutar tareas programadas que monitorean:

- Documentos próximos a vencer o vencidos
- Licitaciones con fechas de presentación próximas
- Contratos próximos a finalizar
- Garantías próximas a vencer o vencidas
- Seguimientos de CRM pendientes
- Ampliaciones y prórrogas pendientes de aprobación

---

## Arquitectura

```
┌─────────────────────────────────────────────────┐
│         Sistema de Alertas Automáticas         │
└─────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────┐
│      APScheduler (Background Scheduler)         │
│  - Ejecuta tareas en horarios específicos       │
│  - Gestiona múltiples jobs concurrentes         │
└─────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────┐
│         AlertGenerator (alert_tasks.py)         │
│  - 6 generadores de alertas especializados      │
│  - Consulta BD para detectar eventos            │
│  - Crea alertas para usuarios configurados      │
└─────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────┐
│            Base de Datos PostgreSQL             │
│  - Lee configuraciones de usuarios              │
│  - Lee entidades (docs, licitaciones, etc.)     │
│  - Inserta alertas generadas                    │
└─────────────────────────────────────────────────┘
```

---

## Módulos Implementados

### 1. `alert_tasks.py`

Contiene la clase `AlertGenerator` con métodos para generar cada tipo de alerta:

#### **Generadores de Alertas:**

1. **`generate_documento_alerts()`**
   - Detecta documentos próximos a vencer
   - Detecta documentos vencidos
   - Prioridad: Crítica (vencidos), Alta/Media (por vencer según días)
   - Frecuencia recomendada: Diaria

2. **`generate_licitacion_alerts()`**
   - Detecta licitaciones con fecha de presentación próxima
   - Solo para licitaciones en estado `publicada` o `en_preparacion`
   - Prioridad: Crítica (≤2 días), Alta (≤5 días), Media (>5 días)
   - Frecuencia recomendada: Diaria

3. **`generate_contrato_alerts()`**
   - Detecta contratos próximos a finalizar
   - Solo para licitaciones en estado `en_ejecucion`
   - Prioridad: Alta (≤15 días), Media (>15 días)
   - Frecuencia recomendada: Diaria

4. **`generate_garantia_alerts()`**
   - Detecta garantías próximas a vencer o vencidas
   - Prioridad: Crítica (vencidas o ≤5 días), Alta (≤10 días), Media (>10 días)
   - Frecuencia recomendada: Diaria

5. **`generate_seguimiento_alerts()`**
   - Detecta seguimientos de CRM pendientes
   - Prioridad: Crítica (atrasados), Alta (hoy), Media (próximos)
   - Frecuencia recomendada: Cada 4 horas

6. **`generate_ampliacion_alerts()`**
   - Detecta ampliaciones/prórrogas pendientes de aprobación
   - Solo alerta si llevan >3 días pendientes
   - Prioridad: Alta (>7 días), Media (3-7 días)
   - Notifica a coordinadores y administradores
   - Frecuencia recomendada: Diaria

7. **`cleanup_old_alerts()`**
   - Archiva alertas resueltas antiguas (>90 días por defecto)
   - Mantiene la BD limpia
   - Frecuencia recomendada: Semanal

---

### 2. `scheduler.py`

Clase `AlertScheduler` que configura y ejecuta las tareas programadas.

#### **Horarios Configurados:**

| Tarea | Frecuencia | Horario | Descripción |
|-------|-----------|---------|-------------|
| `all_alerts` | Diaria | 6:00 AM | Ejecuta TODOS los generadores (resumen matutino) |
| `licitacion_alerts` | Diaria | 7:00 AM | Solo licitaciones |
| `documento_alerts` | Diaria | 8:00 AM | Solo documentos |
| `contrato_alerts` | Diaria | 8:30 AM | Solo contratos |
| `garantia_alerts` | Diaria | 9:00 AM | Solo garantías |
| `ampliacion_alerts` | Diaria | 10:00 AM | Solo ampliaciones |
| `seguimiento_alerts` | Cada 4 horas | - | Seguimientos CRM |
| `cleanup_alerts` | Semanal | Domingos 2:00 AM | Limpieza de alertas antiguas |

---

### 3. `run_worker.py`

Script ejecutable para correr el worker.

#### **Modos de Ejecución:**

```bash
# Modo continuo (producción) - ejecuta según horarios configurados
python run_worker.py

# Ejecutar todas las alertas UNA VEZ y salir (testing)
python run_worker.py --once

# Ejecutar una tarea específica UNA VEZ y salir
python run_worker.py --once --job documento_alerts

# Listar todas las tareas configuradas
python run_worker.py --list-jobs
```

---

## Configuración de Usuarios

Cada usuario puede personalizar qué alertas recibir mediante la tabla `configuracion_alertas`.

### **Campos de Configuración:**

```python
{
    "user_id": 1,
    "alertas_documentos_vencidos": true,
    "dias_alerta_documentos": 15,        # Alertar X días antes
    "alertas_licitaciones_proximas": true,
    "dias_alerta_licitaciones": 7,
    "alertas_contratos_proximos": true,
    "dias_alerta_contratos": 30,
    "alertas_garantias": true,
    "dias_alerta_garantias": 15,
    "notificar_email": true,
    "notificar_push": true,
    "notificar_sms": false,
    "enviar_resumen_diario": true,
    "hora_envio_resumen": 8              # 8:00 AM
}
```

### **API Endpoints:**

```bash
# Obtener mi configuración (auto-crea si no existe)
GET /api/v1/alertas/configuracion/me

# Actualizar mi configuración
PUT /api/v1/alertas/configuracion/me
{
  "dias_alerta_documentos": 20,
  "notificar_email": true
}
```

---

## Lógica de Generación de Alertas

### **Prevención de Duplicados:**

El sistema verifica si ya existe una alerta **activa** o **leída** para el mismo evento antes de crear una nueva. Esto evita spam de alertas.

```python
existing_alert = db.query(Alerta).filter(
    Alerta.user_id == config.user_id,
    Alerta.documento_id == doc.documento_id,
    Alerta.tipo_alerta == "documento_por_vencer",
    Alerta.estado_alerta.in_(["activa", "leida"])
).first()

if not existing_alert:
    # Crear nueva alerta
```

### **Asignación de Prioridad:**

Las prioridades se asignan dinámicamente según la urgencia:

```python
# Ejemplo: Documentos
if dias_restantes <= 3:
    prioridad = "critica"     # Rojo
elif dias_restantes <= 7:
    prioridad = "alta"        # Naranja
else:
    prioridad = "media"       # Amarillo
```

### **Campos de Alertas Generadas:**

```python
{
    "user_id": 1,
    "tipo_alerta": "documento_por_vencer",
    "titulo": "Documento próximo a vencer: Certificación Fiscal",
    "mensaje": "El documento 'Certificación Fiscal' vence en 5 días (el 20/01/2025)",
    "nivel_prioridad": "alta",
    "estado_alerta": "activa",
    "requiere_accion": true,
    "accion_sugerida": "Renovar o actualizar el documento antes de su vencimiento",
    "url_accion": "/documentos/123",
    "documento_id": 123,
    "licitacion_id": 45,
    "fecha_alerta": "2025-01-15T08:00:00",
    "created_by": 1  # Sistema
}
```

---

## Deployment

### **Opción 1: Docker Compose (Recomendado)**

```bash
# Levantar todos los servicios (API + Worker + DB)
docker-compose up -d

# Ver logs del worker
docker-compose logs -f worker

# Reiniciar solo el worker
docker-compose restart worker
```

El `docker-compose.yml` incluye:
- **db**: PostgreSQL
- **api**: FastAPI backend
- **worker**: Alert worker ← NUEVO
- **redis**: Cache (futuro)

### **Opción 2: Proceso Standalone**

```bash
# Activar entorno virtual
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar worker
python run_worker.py

# O en background con nohup
nohup python run_worker.py > worker.log 2>&1 &
```

### **Opción 3: Systemd Service (Linux)**

Crear `/etc/systemd/system/licitaciones-worker.service`:

```ini
[Unit]
Description=Licitaciones Alert Worker
After=network.target postgresql.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/licitaciones/backend
Environment="PATH=/opt/licitaciones/backend/venv/bin"
ExecStart=/opt/licitaciones/backend/venv/bin/python run_worker.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable licitaciones-worker
sudo systemctl start licitaciones-worker
sudo systemctl status licitaciones-worker
```

---

## Testing

### **1. Poblar BD con Datos de Prueba**

```bash
# Crear datos de ejemplo que generarán alertas
python scripts/seed_data.py

# Con limpieza previa
python scripts/seed_data.py --clear
```

El script crea:
- 5 clientes
- 5 licitaciones en diversos estados
- 4 documentos (2 con alertas)
- 3 interacciones CRM (2 con seguimientos pendientes)
- 1 ampliación pendiente (>3 días)
- Configuraciones de alerta para usuario admin

### **2. Generar Alertas Manualmente**

```bash
# Generar TODAS las alertas UNA VEZ
python run_worker.py --once

# Generar solo alertas de documentos
python run_worker.py --once --job documento_alerts

# Generar solo alertas de seguimientos
python run_worker.py --once --job seguimiento_alerts
```

### **3. Verificar Alertas Generadas**

```bash
# Vía API
curl http://localhost:8000/api/v1/alertas \
  -H "Authorization: Bearer YOUR_TOKEN"

# O consultar directamente en PostgreSQL
psql -d licitaciones_db -c "SELECT * FROM alertas ORDER BY fecha_alerta DESC LIMIT 10;"
```

### **4. Ver Estadísticas**

```bash
curl http://localhost:8000/api/v1/alertas/stats \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Monitoreo

### **Logs del Worker**

```bash
# Docker
docker-compose logs -f worker

# Standalone
tail -f worker.log

# Systemd
journalctl -u licitaciones-worker -f
```

### **Formato de Logs**

```
2025-01-14 08:00:00 - app.workers.scheduler - INFO - Starting documento alerts generation
2025-01-14 08:00:01 - app.workers.alert_tasks - INFO - Created 3 document alerts
2025-01-14 08:00:01 - app.workers.scheduler - INFO - Documento alerts completed: 3 alerts created
```

### **Métricas Clave**

- Número de alertas creadas por tipo
- Tiempo de ejecución de cada tarea
- Errores en la generación de alertas
- Alertas archivadas en cleanup

---

## Extensión y Personalización

### **Agregar Nuevo Tipo de Alerta**

1. **Crear generador en `alert_tasks.py`:**

```python
@staticmethod
def generate_custom_alerts(db: Session) -> int:
    alerts_created = 0

    # Tu lógica aquí
    # ...

    db.commit()
    return alerts_created
```

2. **Registrar en `scheduler.py`:**

```python
self.scheduler.add_job(
    func=self._run_custom_alerts,
    trigger=CronTrigger(hour=11, minute=0),
    id='custom_alerts',
    name='Generate custom alerts',
    replace_existing=True
)
```

3. **Agregar método wrapper:**

```python
def _run_custom_alerts(self):
    db = SessionLocal()
    try:
        count = AlertGenerator.generate_custom_alerts(db)
        logger.info(f"Custom alerts completed: {count} alerts created")
    finally:
        db.close()
```

### **Modificar Horarios**

Editar triggers en `scheduler.py`:

```python
# De diario a cada 12 horas
trigger=IntervalTrigger(hours=12)

# Específico (Lunes a Viernes, 9 AM)
trigger=CronTrigger(day_of_week='mon-fri', hour=9, minute=0)

# Múltiples horarios por día
trigger=CronTrigger(hour='8,12,16', minute=0)
```

### **Ajustar Días de Anticipación**

Los usuarios pueden ajustar vía API, pero puedes cambiar defaults en el modelo `ConfiguracionAlertas`:

```python
dias_alerta_documentos = Column(Integer, default=15)  # Cambiar a 30
```

---

## Troubleshooting

### **Worker no inicia**

```bash
# Verificar dependencias
pip install -r requirements.txt

# Verificar conexión a BD
python -c "from app.db.session import SessionLocal; print(SessionLocal())"

# Ejecutar con debug
python -m pdb run_worker.py
```

### **No se generan alertas**

1. **Verificar configuraciones de usuarios:**
   ```sql
   SELECT * FROM configuracion_alertas;
   ```

2. **Verificar datos que deberían generar alertas:**
   ```sql
   -- Documentos próximos a vencer
   SELECT * FROM documentos
   WHERE fecha_vencimiento BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '15 days';
   ```

3. **Ejecutar manualmente con logs:**
   ```bash
   python run_worker.py --once
   ```

### **Alertas duplicadas**

El sistema previene duplicados, pero si ocurre:

1. Verificar lógica de `existing_alert` en `alert_tasks.py`
2. Verificar que estados de alertas se actualizan correctamente
3. Revisar si hay múltiples workers ejecutándose

---

## Best Practices

1. **Producción:**
   - Usar Docker Compose o systemd
   - Monitorear logs activamente
   - Configurar alertas de infraestructura (si worker cae)
   - Backup regular de la BD

2. **Desarrollo:**
   - Usar `--once` para testing
   - Poblar con `seed_data.py` antes de probar
   - Ajustar horarios para testing (cada minuto temporalmente)

3. **Escalabilidad:**
   - Considerar Celery si se necesitan >100 tareas/día
   - Usar Redis para sincronización de múltiples workers
   - Implementar rate limiting en generación de alertas

4. **Mantenimiento:**
   - Ejecutar `cleanup_old_alerts()` regularmente
   - Revisar métricas de alertas mensuales
   - Ajustar días de anticipación según feedback de usuarios

---

## Referencias

- **APScheduler**: https://apscheduler.readthedocs.io/
- **Cron Syntax**: https://crontab.guru/
- **PostgreSQL**: https://www.postgresql.org/docs/
- **FastAPI Background Tasks**: https://fastapi.tiangolo.com/tutorial/background-tasks/

---

## Resumen

El sistema de workers implementado proporciona:

✅ **6 generadores de alertas automáticas**
✅ **8 tareas programadas** con horarios optimizados
✅ **Configuración personalizable** por usuario
✅ **Prevención de duplicados** inteligente
✅ **Deployment flexible** (Docker, standalone, systemd)
✅ **Testing facilitado** con datos de ejemplo
✅ **Monitoreo completo** vía logs
✅ **Extensible y personalizable**

El sistema está listo para producción y puede manejar miles de alertas por día de manera eficiente.
