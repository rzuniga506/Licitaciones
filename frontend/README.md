# Frontend - Sistema de Gestión de Licitaciones

Aplicación web y móvil profesional construida con Flutter.

## 🎨 Características del Diseño

- **Profesional y Corporativo**: Diseño minimalista con paleta neutral
- **100% Responsive**: Funciona perfectamente en móvil, tablet y desktop
- **Material Design 3**: UI moderna y consistente
- **Navegación Fluida**: Sidebar para desktop, bottom nav para móvil
- **Performance**: Optimizado para web y apps nativas

## 🏗️ Arquitectura

```
lib/
├── core/
│   ├── config/           # Configuración de la app
│   ├── models/           # Modelos de datos (Freezed)
│   ├── providers/        # State management (Riverpod)
│   ├── router/           # Navegación (GoRouter)
│   ├── services/         # Servicios API (Dio)
│   ├── theme/            # Theme corporativo
│   └── widgets/          # Widgets reutilizables
│
├── features/             # Features por módulo
│   ├── auth/
│   │   └── presentation/
│   │       └── pages/
│   ├── dashboard/
│   ├── licitaciones/
│   └── alerts/
│
└── main.dart
```

## 🚀 Configuración

### 1. Instalar Dependencias

```bash
flutter pub get
```

### 2. Generar Código (Freezed & JSON)

```bash
# Generar una vez
flutter pub run build_runner build --delete-conflicting-outputs

# O en modo watch (regenera automáticamente)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 3. Configurar URL del Backend

Crear archivo `.env` en la raíz del proyecto frontend:

```env
API_BASE_URL=http://localhost:8000/api/v1
```

O pasar como argumento:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

## 💻 Ejecutar

### Web (Desarrollo)

```bash
flutter run -d chrome --web-port 3000
```

### Web (Producción)

```bash
flutter build web --release
```

Los archivos compilados estarán en `build/web/`

### Android

```bash
flutter run -d android
```

### iOS

```bash
flutter run -d ios
```

## 📱 Pantallas Implementadas

### ✅ Login
- Autenticación con JWT
- Validación de formularios
- Manejo de errores
- Responsive design

### ✅ Dashboard
- KPIs principales (4 cards)
- Actividad reciente
- Próximos vencimientos
- Diseño adaptativo (grid responsive)

### ✅ Licitaciones
- Lista con filtros
- Cards informativos
- Estados con colores
- Indicadores de urgencia

### ✅ Alertas
- Centro de notificaciones
- Tabs por prioridad
- Indicadores visuales
- Ordenamiento por fecha

## 🎨 Theme Corporativo

### Colores Principales

```dart
Primary Blue:   #1E3A8A  (Deep professional blue)
Secondary Blue: #3B82F6  (Bright blue for accents)
Success:        #10B981  (Green)
Warning:        #F59E0B  (Amber)
Error:          #EF4444  (Red)
```

### Neutrals

```dart
Neutral 900:    #111827  (Text primary)
Neutral 700:    #374151  (Text secondary)
Neutral 500:    #6B7280  (Text muted)
Neutral 300:    #D1D5DB  (Borders)
Neutral 100:    #F3F4F6  (Backgrounds light)
Neutral 50:     #F9FAFB  (Backgrounds very light)
```

## 📦 Dependencias Principales

```yaml
# State Management
flutter_riverpod: ^2.4.9

# Networking
dio: ^5.4.0
retrofit: ^4.0.3

# Navigation
go_router: ^13.0.0

# UI
google_fonts: ^6.1.0
fl_chart: ^0.66.0  # Charts

# Code Generation
freezed: ^2.4.6
json_serializable: ^6.7.1
```

## 🔐 Autenticación

El sistema usa JWT con las siguientes características:

- Access token almacenado en Flutter Secure Storage
- Refresh token automático en interceptor
- Logout con limpieza de tokens
- Redirect automático a login si no autenticado

### Credenciales de Prueba

```
Usuario:    admin
Contraseña: admin123
```

## 📐 Breakpoints Responsive

```dart
Mobile:  < 600px
Tablet:  600px - 900px
Desktop: > 900px
```

## 🛠️ Scripts Útiles

```bash
# Analizar código
flutter analyze

# Formatear código
dart format lib/ --set-exit-if-changed

# Ejecutar tests
flutter test

# Clean & Get
flutter clean && flutter pub get
```

## 🚀 Deployment Web

### Docker

```bash
# Build
docker build -t licitaciones-frontend .

# Run
docker run -p 80:80 licitaciones-frontend
```

### Nginx (Producción)

El archivo `nginx.conf` ya está configurado con:
- Gzip compression
- Cache headers
- SPA routing (redirect to index.html)

## 📋 TODO / Mejoras Futuras

- [ ] Integración real con API backend
- [ ] Módulo de Clientes (CRUD)
- [ ] Módulo de Documentos con upload
- [ ] Módulo de CRM
- [ ] Gráficos interactivos en Dashboard (fl_chart)
- [ ] Notificaciones push
- [ ] Dark mode
- [ ] Exportar a PDF/Excel
- [ ] Tests unitarios e integración
- [ ] CI/CD con GitHub Actions

## 📖 Convenciones de Código

- **Nombres de archivos**: snake_case
- **Nombres de clases**: PascalCase
- **Nombres de variables**: camelCase
- **Constantes**: SCREAMING_SNAKE_CASE
- **Widgets privados**: Prefijo con `_`
- **Providers**: Suffix con `Provider`

## 🤝 Contribuir

1. Crear feature branch
2. Implementar cambios
3. Ejecutar `flutter analyze` y `flutter test`
4. Crear Pull Request

## 📄 Licencia

Propiedad privada - Sistema de Gestión de Licitaciones

---

**Desarrollado con** ❤️ **usando Flutter**
