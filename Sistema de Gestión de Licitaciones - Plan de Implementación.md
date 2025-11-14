# 📋 Sistema de Gestión de Licitaciones - Plan de Implementación

## 🎯 Visión General del Proyecto

### Stack Tecnológico
- **Backend**: Python (FastAPI)
- **Frontend**: Flutter (Web/Mobile)
- **Base de Datos**: PostgreSQL
- **Autenticación**: JWT
- **Comunicación**: REST API (snake_case)
- **Seguridad**: HTTPS/TLS, variables de entorno

### Arquitectura General
```
┌─────────────────────────────────────────────────────────────┐
│                     FLUTTER FRONTEND                         │
│  (Web/Android/iOS - Responsive UI - Material Design)        │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTPS/TLS (JWT Bearer Token)
                     │ REST API (snake_case JSON)
┌────────────────────▼────────────────────────────────────────┐
│                   PYTHON BACKEND (FastAPI)                   │
│  ┌──────────────┬──────────────┬──────────────────────────┐ │
│  │   Auth API   │  Business    │   Background Workers     │ │
│  │   (JWT)      │   Logic      │   (Alerts/Notifications) │ │
│  └──────────────┴──────────────┴──────────────────────────┘ │
└────────────────────┬────────────────────────────────────────┘
                     │ SQLAlchemy ORM
┌────────────────────▼────────────────────────────────────────┐
│              PostgreSQL Database                             │
│  (Modular Schema - Relational Design)                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Estructura Modular del Sistema

### Módulos del Sistema
1. **auth** - Autenticación y autorización
2. **users** - Gestión de usuarios y permisos
3. **licitaciones** - Core del sistema (licitaciones)
4. **documentos** - Gestión documental
5. **ampliaciones** - Prórrogas y ampliaciones
6. **clientes** - CRM de clientes/instituciones
7. **alertas** - Sistema de notificaciones
8. **reportes** - Análisis y estadísticas
9. **auditoria** - Logs y trazabilidad

---

## 🗂️ Estructura de Directorios

### Backend (Python/FastAPI)
```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                    # Entry point FastAPI
│   ├── config.py                  # Configuración (.env loader)
│   ├── database.py                # Conexión DB
│   ├── dependencies.py            # Dependencias inyectables
│   │
│   ├── core/
│   │   ├── security.py            # JWT, hashing, encriptación
│   │   ├── config.py              # Settings (Pydantic)
│   │   └── exceptions.py          # Custom exceptions
│   │
│   ├── models/                    # SQLAlchemy Models
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── licitacion.py
│   │   ├── documento.py
│   │   ├── ampliacion.py
│   │   ├── cliente.py
│   │   ├── alerta.py
│   │   └── auditoria.py
│   │
│   ├── schemas/                   # Pydantic Schemas (DTOs)
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── licitacion.py
│   │   ├── documento.py
│   │   └── ...
│   │
│   ├── api/
│   │   ├── __init__.py
│   │   ├── deps.py                # Dependencies (get_current_user)
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── router.py          # Main router
│   │       └── endpoints/
│   │           ├── auth.py
│   │           ├── users.py
│   │           ├── licitaciones.py
│   │           ├── documentos.py
│   │           ├── ampliaciones.py
│   │           ├── clientes.py
│   │           ├── alertas.py
│   │           └── reportes.py
│   │
│   ├── services/                  # Business logic
│   │   ├── licitacion_service.py
│   │   ├── documento_service.py
│   │   ├── alerta_service.py
│   │   └── reporte_service.py
│   │
│   ├── workers/                   # Background tasks
│   │   ├── alerta_worker.py       # Verificar vencimientos
│   │   └── email_worker.py        # Envío de emails
│   │
│   └── utils/
│       ├── date_utils.py
│       ├── validators.py
│       └── enums.py               # Estados, tipos, etc.
│
├── alembic/                       # Migraciones DB
│   ├── versions/
│   └── env.py
│
├── tests/
│   ├── unit/
│   └── integration/
│
├── .env.example
├── requirements.txt
├── alembic.ini
└── README.md
```

### Frontend (Flutter)
```
frontend/
├── lib/
│   ├── main.dart
│   │
│   ├── core/
│   │   ├── config/
│   │   │   ├── api_config.dart       # Base URL, timeout
│   │   │   └── app_config.dart
│   │   ├── constants/
│   │   │   ├── api_endpoints.dart
│   │   │   └── app_constants.dart
│   │   ├── errors/
│   │   │   └── exceptions.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   │
│   ├── data/
│   │   ├── models/                   # DTOs (snake_case JSON)
│   │   │   ├── user_model.dart
│   │   │   ├── licitacion_model.dart
│   │   │   └── ...
│   │   ├── repositories/             # API calls
│   │   │   ├── auth_repository.dart
│   │   │   ├── licitacion_repository.dart
│   │   │   └── ...
│   │   └── data_sources/
│   │       └── api_client.dart       # HTTP client + JWT
│   │
│   ├── domain/
│   │   ├── entities/                 # Business objects
│   │   └── use_cases/                # Business rules
│   │
│   ├── presentation/
│   │   ├── providers/                # State management (Riverpod/Provider)
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   ├── licitaciones/
│   │   │   │   ├── licitaciones_list_screen.dart
│   │   │   │   ├── licitacion_detail_screen.dart
│   │   │   │   └── licitacion_form_screen.dart
│   │   │   ├── documentos/
│   │   │   ├── clientes/
│   │   │   ├── alertas/
│   │   │   └── reportes/
│   │   └── widgets/
│   │       ├── common/
│   │       └── specific/
│   │
│   └── utils/
│       ├── date_formatter.dart
│       ├── validators.dart
│       └── secure_storage.dart       # JWT storage
│
├── assets/
│   ├── images/
│   └── icons/
│
├── test/
├── pubspec.yaml
└── README.md
```

---

## 🔐 Configuración de Seguridad

### Backend (.env example)
```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/licitaciones_db

# Security
SECRET_KEY=your-super-secret-key-change-this-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS
ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com

# Email (para alertas)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Environment
ENVIRONMENT=development
```

### Frontend (api_config.dart)
```dart
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
  
  static const Duration timeout = Duration(seconds: 30);
  static const String tokenKey = 'auth_token';
}
```

---

## 📅 Plan de Implementación por Fases

### **FASE 1: Fundamentos y Autenticación** (Sprint 1-2)
- Setup del proyecto backend y frontend
- Base de datos y migraciones iniciales
- Sistema de autenticación JWT completo
- CRUD de usuarios con roles
- Dashboard básico

### **FASE 2: Módulo Core - Licitaciones** (Sprint 3-4)
- CRUD completo de licitaciones
- Estados y flujo de licitación
- Relación con clientes
- Filtros y búsqueda
- Vista de detalle completa

### **FASE 3: Gestión Documental** (Sprint 5-6)
- Upload/download de documentos
- Control de vencimientos
- Categorización de documentos
- Visor de documentos

### **FASE 4: Ampliaciones y Prórrogas** (Sprint 7)
- CRUD de ampliaciones
- Historial de cambios
- Relación con licitación original

### **FASE 5: CRM de Clientes** (Sprint 8)
- Gestión de clientes/instituciones
- Contactos
- Historial de relación
- Clasificación

### **FASE 6: Sistema de Alertas** (Sprint 9-10)
- Motor de alertas automáticas
- Background workers
- Notificaciones por email
- Panel de alertas en dashboard

### **FASE 7: Reportes y Analytics** (Sprint 11-12)
- Reportes estadísticos
- Gráficas y visualizaciones
- Exportación de datos
- KPIs del negocio

### **FASE 8: Auditoría y Refinamiento** (Sprint 13-14)
- Sistema de logs y auditoría
- Testing completo
- Optimización de performance
- Documentación final

---

## 📊 Convenciones de Código

### Nomenclatura API (snake_case)
```json
{
  "licitacion_id": 123,
  "numero_licitacion": "LIC-2025-001",
  "fecha_presentacion": "2025-01-15",
  "monto_ofertado": 50000.00,
  "estado_licitacion": "en_ejecucion",
  "cliente": {
    "cliente_id": 45,
    "nombre_cliente": "Ministerio de Salud"
  }
}
```

### Response Structure
```json
{
  "success": true,
  "data": { ... },
  "message": "Operación exitosa",
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Datos inválidos",
    "details": { ... }
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

---

## 🚀 Próximos Pasos

1. **Revisar y aprobar** este plan general
2. **Comenzar con FASE 1** - Te entregaré el documento detallado:
   - `FASE_1_fundamentos_autenticacion.md`
3. Implementar fase por fase
4. Iterar y ajustar según necesidades

---

## 📝 Notas Importantes

- Cada fase tendrá su propio documento markdown detallado
- Incluirá código de ejemplo, diagramas y checklist
- Testing en cada fase antes de avanzar
- Documentación continua del API (Swagger/OpenAPI)
- Migrations versionadas con Alembic
- Git flow con branches por feature

---

**¿Listo para comenzar con la FASE 1?** 🚀