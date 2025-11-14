# FASE 1: Fundamentos y Autenticación 🔐

**Duración estimada**: Sprint 1-2 (2-3 semanas)  
**Objetivo**: Establecer la base sólida del proyecto con autenticación segura JWT

---

## 📋 Índice
1. [Objetivos de la Fase](#objetivos)
2. [Setup Inicial Backend](#setup-backend)
3. [Setup Inicial Frontend](#setup-frontend)
4. [Base de Datos](#base-datos)
5. [Implementación Backend](#implementacion-backend)
6. [Implementación Frontend](#implementacion-frontend)
7. [Testing](#testing)
8. [Checklist](#checklist)

---

## 🎯 Objetivos de la Fase {#objetivos}

- ✅ Configurar entorno de desarrollo backend (Python/FastAPI)
- ✅ Configurar entorno de desarrollo frontend (Flutter)
- ✅ Establecer base de datos PostgreSQL
- ✅ Implementar sistema de autenticación JWT
- ✅ CRUD completo de usuarios con roles
- ✅ Protección de rutas y middlewares
- ✅ Dashboard básico con navegación
- ✅ Manejo de errores y validaciones

---

## 🔧 Setup Inicial Backend {#setup-backend}

### 1. Crear estructura del proyecto

```bash
mkdir licitaciones-backend
cd licitaciones-backend
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
```

### 2. Instalar dependencias

**requirements.txt**
```txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
alembic==1.12.1
pydantic==2.5.0
pydantic-settings==2.1.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
python-dotenv==1.0.0
email-validator==2.1.0
```

```bash
pip install -r requirements.txt
```

### 3. Configuración inicial

**.env**
```bash
# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/licitaciones_db

# Security
SECRET_KEY=09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# App
PROJECT_NAME="Sistema de Licitaciones"
VERSION="1.0.0"
API_V1_PREFIX="/api/v1"

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

**app/core/config.py**
```python
from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    PROJECT_NAME: str
    VERSION: str
    API_V1_PREFIX: str
    
    DATABASE_URL: str
    
    SECRET_KEY: str
    ALGORITHM: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int
    
    ALLOWED_ORIGINS: List[str] = []
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
```

---

## 📱 Setup Inicial Frontend {#setup-frontend}

### 1. Crear proyecto Flutter

```bash
flutter create licitaciones_frontend
cd licitaciones_frontend
```

### 2. Dependencias

**pubspec.yaml**
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP & API
  dio: ^5.4.0
  retrofit: ^4.0.3
  json_annotation: ^4.8.1
  
  # State Management
  flutter_riverpod: ^2.4.9
  
  # Storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2
  
  # UI
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  
  # Utils
  intl: ^0.18.1
  logger: ^2.0.2+1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
  retrofit_generator: ^8.0.4
  json_serializable: ^6.7.1
```

```bash
flutter pub get
```

---

## 🗄️ Base de Datos {#base-datos}

### Esquema de la Fase 1

```sql
-- Tabla de usuarios
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'analista',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);

-- Insertar usuario admin por defecto
INSERT INTO users (email, username, hashed_password, full_name, role)
VALUES (
    'admin@licitaciones.com',
    'admin',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7cbp6r3MRK', -- password: admin123
    'Administrador del Sistema',
    'administrador'
);
```

### Roles del sistema

- **administrador**: Acceso completo al sistema
- **gerente**: Visualización y edición de todo
- **analista**: Operaciones del día a día
- **asistente**: Solo lectura

---

## 💻 Implementación Backend {#implementacion-backend}

### 1. Modelo de Usuario

**app/models/user.py**
```python
from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.sql import func
from app.database import Base

class User(Base):
    __tablename__ = "users"
    
    user_id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    role = Column(String, nullable=False, default="analista")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
```

### 2. Schemas Pydantic

**app/schemas/user.py**
```python
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=100)
    full_name: str = Field(..., min_length=1, max_length=255)
    role: str = Field(default="analista")

class UserCreate(UserBase):
    password: str = Field(..., min_length=6)

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None

class UserInDB(UserBase):
    user_id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime]
    
    class Config:
        from_attributes = True

class UserResponse(UserInDB):
    pass

# Auth schemas
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    user_id: Optional[int] = None
    username: Optional[str] = None

class LoginRequest(BaseModel):
    username: str
    password: str
```

### 3. Seguridad y JWT

**app/core/security.py**
```python
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def decode_access_token(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError:
        return None
```

### 4. Dependencias de Autenticación

**app/api/deps.py**
```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import Optional

from app.database import get_db
from app.core.security import decode_access_token
from app.models.user import User
from app.schemas.user import TokenData

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudo validar las credenciales",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    token = credentials.credentials
    payload = decode_access_token(token)
    
    if payload is None:
        raise credentials_exception
    
    user_id: int = payload.get("sub")
    if user_id is None:
        raise credentials_exception
    
    user = db.query(User).filter(User.user_id == user_id).first()
    if user is None:
        raise credentials_exception
    
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Usuario inactivo")
    
    return user

def require_role(allowed_roles: list):
    def role_checker(current_user: User = Depends(get_current_user)):
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Rol no autorizado. Requiere: {', '.join(allowed_roles)}"
            )
        return current_user
    return role_checker
```

### 5. Endpoints de Autenticación

**app/api/v1/endpoints/auth.py**
```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta

from app.database import get_db
from app.core.security import verify_password, create_access_token
from app.core.config import settings
from app.models.user import User
from app.schemas.user import Token, LoginRequest, UserResponse
from app.api.deps import get_current_user

router = APIRouter()

@router.post("/login", response_model=Token)
def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    """Iniciar sesión con username y password"""
    user = db.query(User).filter(User.username == login_data.username).first()
    
    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Usuario inactivo"
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.user_id, "username": user.username, "role": user.role},
        expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserResponse)
def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Obtener información del usuario autenticado"""
    return current_user

@router.post("/logout")
def logout(current_user: User = Depends(get_current_user)):
    """Cerrar sesión (el cliente debe eliminar el token)"""
    return {"message": "Sesión cerrada exitosamente"}
```

### 6. Endpoints de Usuarios

**app/api/v1/endpoints/users.py**
```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate, UserResponse
from app.core.security import get_password_hash
from app.api.deps import get_current_user, require_role

router = APIRouter()

@router.get("/", response_model=List[UserResponse])
def get_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["administrador", "gerente"]))
):
    """Listar todos los usuarios (solo admin y gerentes)"""
    users = db.query(User).offset(skip).limit(limit).all()
    return users

@router.get("/{user_id}", response_model=UserResponse)
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Obtener un usuario por ID"""
    # Solo admin/gerente pueden ver otros usuarios
    if current_user.role not in ["administrador", "gerente"] and current_user.user_id != user_id:
        raise HTTPException(status_code=403, detail="No autorizado")
    
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return user

@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def create_user(
    user_data: UserCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["administrador"]))
):
    """Crear nuevo usuario (solo administradores)"""
    # Verificar si el email ya existe
    if db.query(User).filter(User.email == user_data.email).first():
        raise HTTPException(status_code=400, detail="Email ya registrado")
    
    # Verificar si el username ya existe
    if db.query(User).filter(User.username == user_data.username).first():
        raise HTTPException(status_code=400, detail="Username ya registrado")
    
    # Crear usuario
    db_user = User(
        email=user_data.email,
        username=user_data.username,
        hashed_password=get_password_hash(user_data.password),
        full_name=user_data.full_name,
        role=user_data.role
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@router.put("/{user_id}", response_model=UserResponse)
def update_user(
    user_id: int,
    user_data: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["administrador"]))
):
    """Actualizar usuario (solo administradores)"""
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    update_data = user_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)
    
    db.commit()
    db.refresh(user)
    return user

@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["administrador"]))
):
    """Eliminar usuario (solo administradores)"""
    if current_user.user_id == user_id:
        raise HTTPException(status_code=400, detail="No puedes eliminarte a ti mismo")
    
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    db.delete(user)
    db.commit()
    return None
```

### 7. Main Application

**app/main.py**
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.v1 import router as api_router
from app.database import engine, Base

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

# Router principal
app.include_router(api_router, prefix=settings.API_V1_PREFIX)

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

**app/api/v1/__init__.py**
```python
from fastapi import APIRouter
from app.api.v1.endpoints import auth, users

router = APIRouter()

router.include_router(auth.router, prefix="/auth", tags=["Autenticación"])
router.include_router(users.router, prefix="/users", tags=["Usuarios"])
```

**app/database.py**
```python
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

---

## 📱 Implementación Frontend {#implementacion-frontend}

### 1. Configuración API

**lib/core/config/api_config.dart**
```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const Duration timeout = Duration(seconds: 30);
  
  // Endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String users = '/users';
}
```

### 2. Modelos

**lib/data/models/user_model.dart**
```dart
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserModel {
  final int userId;
  final String email;
  final String username;
  final String fullName;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.userId,
    required this.email,
    required this.username,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TokenResponse {
  final String accessToken;
  final String tokenType;

  TokenResponse({required this.accessToken, required this.tokenType});

  factory TokenResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenResponseFromJson(json);
}
```

### 3. API Client con JWT

**lib/data/data_sources/api_client.dart**
```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/api_config.dart';

class ApiClient {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Interceptor para agregar token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await clearToken();
          // Aquí puedes navegar al login
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }
}
```

### 4. Repository de Autenticación

**lib/data/repositories/auth_repository.dart**
```dart
import '../data_sources/api_client.dart';
import '../models/user_model.dart';
import '../../core/config/api_config.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<TokenResponse> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.login,
        data: LoginRequest(username: username, password: password).toJson(),
      );

      final tokenResponse = TokenResponse.fromJson(response.data);
      await _apiClient.saveToken(tokenResponse.accessToken);
      return tokenResponse;
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.me);
      return UserModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiConfig.logout);
      await _apiClient.clearToken();
    } catch (e) {
      await _apiClient.clearToken();
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  Future<bool> isAuthenticated() async {
    return await _apiClient.isAuthenticated();
  }
}
```

### 5. Pantalla de Login

**lib/presentation/screens/auth/login_screen.dart**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Aquí integrarás con tu AuthRepository/Provider
      // await ref.read(authProvider.notifier).login(
      //   _usernameController.text,
      //   _passwordController.text,
      // );
      
      // Navegar al dashboard
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Icon(
                    Icons.description,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  
                  // Título
                  Text(
                    'Sistema de Licitaciones',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para continuar',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 48),
                  
                  // Campo de usuario
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu usuario';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo de contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón de login
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Iniciar Sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 🧪 Testing {#testing}

### Backend Tests

**tests/test_auth.py**
```python
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_login_success():
    response = client.post(
        "/api/v1/auth/login",
        json={"username": "admin", "password": "admin123"}
    )
    assert response.status_code == 200
    assert "access_token" in response.json()
    assert response.json()["token_type"] == "bearer"

def test_login_invalid_credentials():
    response = client.post(
        "/api/v1/auth/login",
        json={"username": "admin", "password": "wrongpassword"}
    )
    assert response.status_code == 401

def test_protected_route_without_token():
    response = client.get("/api/v1/auth/me")
    assert response.status_code == 401

def test_protected_route_with_token():
    # Login primero
    login_response = client.post(
        "/api/v1/auth/login",
        json={"username": "admin", "password": "admin123"}
    )
    token = login_response.json()["access_token"]
    
    # Acceder a ruta protegida
    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    assert "email" in response.json()
```

---

## ✅ Checklist de Completitud {#checklist}

### Backend
- [ ] Proyecto configurado con estructura modular
- [ ] Base de datos PostgreSQL conectada
- [ ] Modelo User creado y migrado
- [ ] Sistema JWT implementado (generación y validación)
- [ ] Middleware de autenticación funcionando
- [ ] Endpoint `/auth/login` funcionando
- [ ] Endpoint `/auth/me` funcionando
- [ ] Endpoint `/auth/logout` funcionando
- [ ] CRUD completo de usuarios
- [ ] Sistema de roles implementado
- [ ] Validaciones de Pydantic funcionando
- [ ] Manejo de errores con mensajes claros
- [ ] CORS configurado correctamente
- [ ] Variables de entorno cargadas desde .env
- [ ] Tests básicos pasando
- [ ] Documentación Swagger generada automáticamente

### Frontend
- [ ] Proyecto Flutter creado y configurado
- [ ] Dependencias instaladas
- [ ] ApiClient con Dio configurado
- [ ] Interceptor JWT implementado
- [ ] Secure Storage para token configurado
- [ ] Modelos con snake_case funcionando
- [ ] AuthRepository implementado
- [ ] Login screen con formulario
- [ ] Validaciones de formulario
- [ ] Manejo de estados (loading, error, success)
- [ ] Navegación al dashboard después del login
- [ ] Manejo de errores con SnackBars
- [ ] Logout funcionando
- [ ] Persistencia de sesión al reabrir app

### Integración
- [ ] Backend corriendo en `http://localhost:8000`
- [ ] Frontend puede hacer login exitosamente
- [ ] Token se guarda en secure storage
- [ ] Token se envía en requests subsecuentes
- [ ] Refresh automático en token expirado
- [ ] Logout limpia el token correctamente
- [ ] CORS permite requests desde frontend

---

## 🚀 Comandos de Ejecución

### Backend
```bash
# Activar entorno virtual
source venv/bin/activate  # Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Crear base de datos (si no existe)
createdb licitaciones_db

# Ejecutar migraciones (opcional con Alembic)
alembic upgrade head

# Correr servidor
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Ver documentación automática
# http://localhost:8000/docs
```

### Frontend
```bash
# Instalar dependencias
flutter pub get

# Generar código (modelos JSON)
flutter pub run build_runner build --delete-conflicting-outputs

# Correr en web
flutter run -d chrome

# Correr en Android/iOS
flutter run
```

---

## 📊 Criterios de Aceptación

### Funcionales
1. ✅ Un usuario puede iniciar sesión con username y password
2. ✅ El sistema genera un JWT válido al login exitoso
3. ✅ El token se almacena de forma segura en el cliente
4. ✅ Las rutas protegidas verifican el token correctamente
5. ✅ Solo usuarios con rol "administrador" pueden crear usuarios
6. ✅ Los usuarios pueden ver su propia información
7. ✅ El sistema rechaza tokens inválidos o expirados
8. ✅ El logout elimina el token del cliente

### No Funcionales
1. ✅ Las contraseñas se almacenan hasheadas (bcrypt)
2. ✅ La comunicación usa HTTPS en producción
3. ✅ Los tokens expiran después de 30 minutos
4. ✅ El código sigue las convenciones (snake_case API)
5. ✅ La UI es responsive y funciona en mobile/web
6. ✅ Los errores muestran mensajes claros al usuario
7. ✅ El código está organizado de forma modular

---

## 🐛 Troubleshooting Común

### Backend

**Error: "could not connect to database"**
```bash
# Verificar que PostgreSQL esté corriendo
sudo service postgresql status  # Linux
brew services list  # Mac

# Crear base de datos si no existe
createdb licitaciones_db
```

**Error: "SECRET_KEY not found"**
```bash
# Asegúrate de tener el archivo .env
cp .env.example .env
# Edita .env con tus valores
```

**Error: "CORS policy blocked"**
```python
# Verifica que el origen esté en ALLOWED_ORIGINS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

### Frontend

**Error: "Connection refused"**
```dart
// En Android emulator, usa 10.0.2.2 en vez de localhost
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
```

**Error: "Bad state: No element"**
```dart
// Asegúrate de generar los archivos .g.dart
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📚 Recursos Adicionales

### Documentación
- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [SQLAlchemy Docs](https://docs.sqlalchemy.org/)
- [Flutter Docs](https://docs.flutter.dev/)
- [Dio Package](https://pub.dev/packages/dio)
- [JWT.io](https://jwt.io/)

### Herramientas de Testing
- **Postman/Insomnia**: Para probar endpoints manualmente
- **Swagger UI**: Disponible en `http://localhost:8000/docs`
- **Flutter DevTools**: Para debugging de Flutter

---

## ➡️ Próximos Pasos

Una vez completada esta fase, estarás listo para:

1. **FASE 2**: Módulo Core de Licitaciones
   - CRUD de licitaciones
   - Estados y flujos
   - Filtros y búsqueda avanzada

---

## 📝 Notas Finales

- **Seguridad**: Nunca commiteees el archivo `.env` con credenciales reales
- **Testing**: Ejecuta tests antes de cada commit
- **Git**: Usa commits descriptivos y pequeños
- **Code Review**: Revisa el código antes de mergear
- **Documentación**: Actualiza los comentarios al modificar código

---

**✅ FASE 1 COMPLETADA** - Continúa con **FASE 2**