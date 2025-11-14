# Sistema de Gestión de Licitaciones

Sistema completo para la gestión de licitaciones, contratos y documentación asociada.

## 🏗️ Arquitectura

- **Backend**: FastAPI + PostgreSQL + SQLAlchemy
- **Frontend**: Flutter (Web + Mobile)
- **Cache**: Redis
- **Contenedores**: Docker + Docker Compose

## 📋 Requisitos Previos

- Docker y Docker Compose
- Python 3.11+ (para desarrollo local)
- Flutter 3.x+ (para desarrollo frontend)
- PostgreSQL 15+ (opcional, para desarrollo local)

## 🚀 Inicio Rápido

### 1. Clonar el repositorio

```bash
git clone <repository-url>
cd Licitaciones
```

### 2. Configurar variables de entorno

Copiar el archivo de ejemplo y configurar:

```bash
cp backend/.env.example backend/.env
```

Editar `backend/.env` con los valores apropiados.

### 3. Iniciar con Docker Compose

```bash
docker-compose up -d
```

Esto iniciará:
- PostgreSQL (puerto 5432)
- Redis (puerto 6379)
- Backend API (puerto 8000)

### 4. Verificar la instalación

- API Documentation: http://localhost:8000/api/v1/docs
- Health Check: http://localhost:8000/health

## 📚 Estructura del Proyecto

```
Licitaciones/
├── backend/                 # API Backend
│   ├── alembic/            # Migraciones de BD
│   ├── app/
│   │   ├── api/            # Endpoints API
│   │   ├── core/           # Configuración y seguridad
│   │   ├── db/             # Configuración de BD
│   │   ├── models/         # Modelos SQLAlchemy
│   │   ├── schemas/        # Schemas Pydantic
│   │   ├── services/       # Lógica de negocio
│   │   └── utils/          # Utilidades
│   ├── requirements.txt    # Dependencias Python
│   └── Dockerfile
├── frontend/               # Aplicación Flutter
│   └── lib/
│       ├── models/
│       ├── providers/
│       ├── screens/
│       ├── services/
│       └── widgets/
├── docs/                   # Documentación del proyecto
├── scripts/                # Scripts de utilidad
├── docker-compose.yml      # Configuración Docker
└── README.md
```

## 🔧 Desarrollo Local

### Backend

1. Crear entorno virtual:
```bash
cd backend
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
```

2. Instalar dependencias:
```bash
pip install -r requirements.txt
```

3. Ejecutar migraciones:
```bash
alembic upgrade head
```

4. Iniciar servidor de desarrollo:
```bash
uvicorn app.main:app --reload
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome  # Para web
flutter run            # Para móvil
```

## 🗄️ Base de Datos

### Crear nueva migración

```bash
cd backend
alembic revision --autogenerate -m "Descripción del cambio"
```

### Aplicar migraciones

```bash
alembic upgrade head
```

### Revertir última migración

```bash
alembic downgrade -1
```

## 🧪 Testing

### Backend

```bash
cd backend
pytest
pytest --cov=app tests/  # Con cobertura
```

### Frontend

```bash
cd frontend
flutter test
```

## 📖 Fases de Implementación

1. ✅ **Fase 1**: Fundamentos y Autenticación
2. ⏳ **Fase 2**: Módulo Core de Licitaciones
3. ⏳ **Fase 3**: Gestión Documental
4. ⏳ **Fase 4**: Ampliaciones y Prórrogas
5. ⏳ **Fase 5**: CRM
6. ⏳ **Fase 6**: Sistema de Alertas
7. ⏳ **Fase 7**: Reportes y Analytics
8. ⏳ **Fase 8**: Auditoría y Refinamiento

## 🔐 Roles de Usuario

- **admin**: Acceso completo al sistema
- **coordinator**: Gestión de licitaciones y usuarios
- **analyst**: Operaciones del día a día
- **viewer**: Solo lectura

## 📝 API Endpoints

### Autenticación
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/refresh` - Refresh token
- `POST /api/v1/auth/logout` - Logout

### Usuarios
- `GET /api/v1/users/me` - Usuario actual
- `GET /api/v1/users/` - Listar usuarios
- `POST /api/v1/users/` - Crear usuario
- `PUT /api/v1/users/{id}` - Actualizar usuario
- `DELETE /api/v1/users/{id}` - Eliminar usuario

Ver la documentación completa en: http://localhost:8000/api/v1/docs

## 🤝 Contribución

1. Fork el proyecto
2. Crear una rama feature (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## 📄 Licencia

Este proyecto es privado y confidencial.

## 📧 Contacto

Para consultas sobre el proyecto, contactar al equipo de desarrollo.
