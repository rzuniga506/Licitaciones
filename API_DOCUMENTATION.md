# API Documentation - Sistema de Gestión de Licitaciones

## Base URL
```
http://localhost:8000/api/v1
```

## Authentication

All protected endpoints require a valid JWT token in the Authorization header:
```
Authorization: Bearer <access_token>
```

### Authentication Endpoints

#### POST `/auth/login`
Login to get access token.

**Request:**
```json
{
  "username": "admin",
  "password": "admin123"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 1800
}
```

#### POST `/auth/refresh`
Refresh access token using refresh token.

#### POST `/auth/logout`
Logout (client-side token removal).

---

## Users

### GET `/users/me`
Get current authenticated user information.

### GET `/users`
List users with pagination and filters.

**Query Parameters:**
- `skip` (int): Number of records to skip (default: 0)
- `limit` (int): Maximum records to return (default: 100, max: 100)
- `role` (string): Filter by role
- `is_active` (boolean): Filter by active status

### GET `/users/{user_id}`
Get user by ID.

### POST `/users`
Create new user (admin only).

**Request:**
```json
{
  "email": "user@example.com",
  "username": "newuser",
  "full_name": "John Doe",
  "password": "securepassword",
  "role": "analyst"
}
```

### PUT `/users/{user_id}`
Update user information.

### DELETE `/users/{user_id}`
Delete user (soft delete, admin only).

### POST `/users/change-password`
Change current user's password.

---

## Clientes

### GET `/clientes`
List clientes with pagination and filters.

**Query Parameters:**
- `page` (int): Page number (default: 1)
- `page_size` (int): Items per page (default: 20, max: 100)
- `tipo_cliente` (string): Filter by tipo (publico/privado)
- `is_active` (boolean): Filter by active status
- `search` (string): Search in nombre, identificacion, email, contacto

**Response:**
```json
{
  "total": 150,
  "items": [...],
  "page": 1,
  "page_size": 20,
  "total_pages": 8
}
```

### GET `/clientes/{cliente_id}`
Get cliente by ID.

### POST `/clientes`
Create new cliente (analyst role or higher).

**Request:**
```json
{
  "nombre_cliente": "Ministerio de Educación",
  "tipo_cliente": "publico",
  "identificacion": "3-101-123456",
  "telefono": "2222-3333",
  "email": "contacto@mep.go.cr",
  "direccion": "San José, Costa Rica",
  "contacto_principal": "Juan Pérez",
  "notas": "Cliente VIP"
}
```

### PUT `/clientes/{cliente_id}`
Update cliente information (analyst role or higher).

### DELETE `/clientes/{cliente_id}`
Delete cliente (analyst role or higher).

### GET `/clientes/{cliente_id}/stats`
Get statistics for a specific cliente.

**Response:**
```json
{
  "cliente_id": 1,
  "nombre_cliente": "Ministerio de Educación",
  "total_licitaciones": 25,
  "licitaciones_adjudicadas": 18,
  "licitaciones_en_proceso": 5,
  "monto_total_adjudicado": 15000000.00,
  "tasa_exito": 72.0
}
```

---

## Licitaciones

### GET `/licitaciones`
List licitaciones with advanced filters and pagination.

**Query Parameters:**
- `page` (int): Page number
- `page_size` (int): Items per page (max: 100)
- `cliente_id` (int): Filter by cliente
- `estado` (string): Filter by estado
  - `en_preparacion`, `presentada`, `en_evaluacion`, `adjudicada`, `en_ejecucion`, `finalizada`, `desierta`, `rechazada`
- `categoria` (string): Filter by categoria
  - `servicios`, `obras`, `bienes`, `consultoria`
- `prioridad` (string): Filter by prioridad
  - `alta`, `media`, `baja`
- `search` (string): Search in numero, nombre, descripcion, expediente
- `fecha_desde` (date): Filter from date (fecha_presentacion)
- `fecha_hasta` (date): Filter to date (fecha_presentacion)
- `order_by` (string): Sort field (default: `fecha_presentacion`)
- `order_desc` (boolean): Sort descending (default: true)

### GET `/licitaciones/stats`
Get general licitaciones statistics.

**Response:**
```json
{
  "total_licitaciones": 120,
  "por_estado": {
    "en_preparacion": 15,
    "presentada": 25,
    "adjudicada": 50,
    "finalizada": 30
  },
  "por_categoria": {
    "servicios": 45,
    "obras": 35,
    "bienes": 40
  },
  "monto_total_ofertado": 50000000.00,
  "monto_total_adjudicado": 35000000.00,
  "tasa_exito": 70.5
}
```

### GET `/licitaciones/venciendo`
Get licitaciones expiring in X days.

**Query Parameters:**
- `dias` (int): Days until expiration (default: 15, max: 90)

### GET `/licitaciones/{licitacion_id}`
Get licitacion by ID.

### POST `/licitaciones`
Create new licitacion (analyst role or higher).

**Request:**
```json
{
  "numero_licitacion": "2025-001-LIC",
  "cliente_id": 1,
  "nombre_licitacion": "Servicios de Consultoría IT",
  "descripcion": "Desarrollo de sistema web",
  "objeto_contrato": "Diseño, desarrollo e implementación",
  "monto_ofertado": 5000000.00,
  "moneda": "CRC",
  "estado_licitacion": "en_preparacion",
  "fecha_publicacion": "2025-01-15",
  "fecha_presentacion": "2025-02-15",
  "tipo_licitacion": "publica",
  "categoria": "servicios",
  "prioridad": "alta",
  "url_portal_compras": "https://...",
  "numero_expediente": "EXP-2025-001"
}
```

### PUT `/licitaciones/{licitacion_id}`
Update licitacion information (analyst role or higher).

### PATCH `/licitaciones/{licitacion_id}/estado`
Change licitacion estado (analyst role or higher).

**Query Parameters:**
- `nuevo_estado` (string): New estado (required)
- `motivo_rechazo` (string): Rejection reason (required if estado=rechazada)

### DELETE `/licitaciones/{licitacion_id}`
Delete licitacion (coordinator role or higher).

Can only delete licitaciones in states: `en_preparacion`, `desierta`, `rechazada`

---

## Documentos

### GET `/documentos`
List documentos with advanced filters and pagination.

**Query Parameters:**
- `page` (int): Page number
- `page_size` (int): Items per page (max: 100)
- `licitacion_id` (int): Filter by licitacion
- `tipo_documento` (string): Filter by tipo
- `estado_documento` (string): Filter by estado (activo, vencido, archivado)
- `vencimiento_desde/hasta` (date): Filter by expiration date range
- `search` (string): Search in nombre, descripcion, filename
- `tags` (string): Comma-separated tags to filter

### GET `/documentos/venciendo`
Get documentos expiring in next X days.

**Query Parameters:**
- `dias` (int): Days until expiration (default: 15, max: 90)

### GET `/documentos/vencidos`
Get all expired documentos.

### GET `/documentos/{documento_id}`
Get documento by ID.

### GET `/documentos/{documento_id}/versions`
Get all versions of a documento.

### GET `/documentos/{documento_id}/download`
Download documento file.

### POST `/documentos`
Create new documento metadata (without file).

### POST `/documentos/upload`
Upload a new documento with file.

**Request (multipart/form-data):**
- `licitacion_id` (int): Required
- `nombre_documento` (string): Required
- `tipo_documento` (string): Required
- `file` (file): Required
- `descripcion` (string): Optional
- `fecha_vencimiento` (date): Optional
- `es_confidencial` (boolean): Default false
- `tags` (string): Comma-separated tags

**Response:**
```json
{
  "documento_id": 1,
  "nombre_documento": "Oferta Técnica",
  "tipo_documento": "oferta_tecnica",
  "nombre_archivo_original": "oferta_v1.pdf",
  "tamano_bytes": 1024000,
  "hash_archivo": "a1b2c3d4...",
  "version": 1,
  "estado_documento": "activo"
}
```

### POST `/documentos/{documento_id}/new-version`
Upload a new version of existing documento.

### PUT `/documentos/{documento_id}`
Update documento metadata (analyst role or higher).

### DELETE `/documentos/{documento_id}`
Delete documento (coordinator role or higher).

---

## Ampliaciones y Prórrogas

### Ampliaciones

#### GET `/modificaciones/ampliaciones`
List ampliaciones with filters and pagination.

**Query Parameters:**
- `page`, `page_size`: Pagination
- `licitacion_id` (int): Filter by licitacion
- `tipo_ampliacion` (string): Filter by tipo (plazo, monto, alcance)
- `estado_ampliacion` (string): Filter by estado (pendiente, aprobada, rechazada)
- `search` (string): Search in descripcion, justificacion

#### GET `/modificaciones/ampliaciones/{ampliacion_id}`
Get ampliacion by ID.

#### POST `/modificaciones/ampliaciones`
Create new ampliacion (analyst role or higher).

**Request:**
```json
{
  "licitacion_id": 1,
  "tipo_ampliacion": "monto",
  "descripcion": "Ampliación por trabajos adicionales",
  "justificacion": "Se requieren servicios no contemplados inicialmente",
  "fecha_anterior_fin": "2025-06-30",
  "fecha_nueva_fin": "2025-09-30",
  "monto_anterior": 5000000.00,
  "monto_nuevo": 7000000.00,
  "monto_ampliacion": 2000000.00
}
```

#### PATCH `/modificaciones/ampliaciones/{id}/approve`
Approve ampliacion (coordinator role or higher).

**Query Parameters:**
- `aprobada_por` (string): Required
- `observaciones_aprobacion` (string): Optional

#### PATCH `/modificaciones/ampliaciones/{id}/reject`
Reject ampliacion with reason (coordinator role or higher).

#### PUT `/modificaciones/ampliaciones/{id}`
Update ampliacion (analyst role or higher).

#### DELETE `/modificaciones/ampliaciones/{id}`
Delete ampliacion (coordinator role or higher).

### Prórrogas

#### GET `/modificaciones/prorrogas`
List prorrogas with filters and pagination.

**Query Parameters:**
- `page`, `page_size`: Pagination
- `licitacion_id` (int): Filter by licitacion
- `estado_prorroga` (string): Filter by estado
- `search` (string): Search in descripcion, justificacion

#### POST `/modificaciones/prorrogas`
Create new prorroga (analyst role or higher).

**Request:**
```json
{
  "licitacion_id": 1,
  "descripcion": "Prórroga por atrasos",
  "justificacion": "Condiciones climáticas adversas",
  "fecha_fin_anterior": "2025-06-30",
  "fecha_fin_nueva": "2025-09-30"
}
```

Note: `dias_prorrogados` is calculated automatically.

#### PATCH `/modificaciones/prorrogas/{id}/approve`
Approve prorroga (coordinator role or higher).

#### PATCH `/modificaciones/prorrogas/{id}/reject`
Reject prorroga (coordinator role or higher).

---

## CRM (Contactos e Interacciones)

### Contactos

#### GET `/crm/contactos`
List contactos with filters and pagination.

**Query Parameters:**
- `page`, `page_size`: Pagination
- `cliente_id` (int): Filter by cliente
- `is_active` (boolean): Filter by active status
- `es_contacto_principal` (boolean): Filter principal contacts
- `nivel_decision` (string): Filter by decision level (alto, medio, bajo)
- `search` (string): Search in nombre, cargo, email, telefono, departamento

#### GET `/crm/contactos/{contacto_id}`
Get contacto by ID.

#### POST `/crm/contactos`
Create new contacto (analyst role or higher).

**Request:**
```json
{
  "cliente_id": 1,
  "nombre_contacto": "Juan Pérez",
  "cargo": "Director de Compras",
  "departamento": "Adquisiciones",
  "email": "jperez@cliente.com",
  "telefono": "2222-3333",
  "nivel_decision": "alto",
  "es_contacto_principal": true
}
```

If `es_contacto_principal=true`, other principal contacts for this cliente are automatically set to false.

#### PUT `/crm/contactos/{contacto_id}`
Update contacto (analyst role or higher).

#### DELETE `/crm/contactos/{contacto_id}`
Delete contacto (coordinator role or higher).

### Interacciones Cliente

#### GET `/crm/interacciones`
List interacciones with filters and pagination.

**Query Parameters:**
- `page`, `page_size`: Pagination
- `cliente_id` (int): Filter by cliente
- `contacto_id` (int): Filter by contacto
- `tipo_interaccion` (string): Filter by tipo (llamada, reunion, email, visita, presentacion)
- `requiere_seguimiento` (boolean): Filter by follow-up requirement
- `fecha_desde/hasta` (datetime): Filter by interaction date range
- `search` (string): Search in descripcion, resultado, proximos_pasos

#### GET `/crm/interacciones/seguimientos-pendientes`
Get interacciones requiring follow-up in next X days.

**Query Parameters:**
- `dias` (int): Days to look ahead (default: 7, max: 30)

#### POST `/crm/interacciones`
Create new interaccion (analyst role or higher).

**Request:**
```json
{
  "cliente_id": 1,
  "contacto_id": 5,
  "tipo_interaccion": "reunion",
  "fecha_interaccion": "2025-01-15T10:00:00",
  "descripcion": "Reunión de seguimiento proyecto X",
  "resultado": "Positivo, interesados en ampliar contrato",
  "requiere_seguimiento": true,
  "fecha_seguimiento": "2025-02-15",
  "proximos_pasos": "Enviar propuesta de ampliación",
  "participantes": ["Juan Pérez", "María González"]
}
```

#### PUT `/crm/interacciones/{interaccion_id}`
Update interaccion (analyst role or higher).

#### DELETE `/crm/interacciones/{interaccion_id}`
Delete interaccion (coordinator role or higher).

---

## Alertas

### GET `/alertas`
List alertas with filters and pagination.

**Query Parameters:**
- `page`, `page_size`: Pagination
- `user_id` (int): Filter by user (defaults to current user if not admin)
- `tipo_alerta` (string): Filter by tipo
- `estado_alerta` (string): Filter by estado (activa, leida, resuelta, archivada, descartada)
- `nivel_prioridad` (string): Filter by prioridad (critica, alta, media, baja)
- `requiere_accion` (boolean): Filter by action requirement
- `licitacion_id` (int): Filter by licitacion
- `cliente_id` (int): Filter by cliente
- `search` (string): Search in titulo, mensaje

Alertas are ordered by priority (critical first) and date (newest first).

### GET `/alertas/stats`
Get alertas statistics.

**Response:**
```json
{
  "total_alertas": 25,
  "por_estado": {
    "activa": 10,
    "leida": 8,
    "resuelta": 7
  },
  "por_tipo": {
    "documento_vencido": 5,
    "licitacion_proxima": 8
  },
  "por_prioridad": {
    "critica": 2,
    "alta": 10,
    "media": 13
  },
  "activas_criticas": 2,
  "requieren_accion": 5
}
```

### POST `/alertas`
Create new alerta (analyst role or higher).

**Supported tipos:**
- `documento_vencido`, `documento_por_vencer`
- `contrato_proximo_fin`
- `garantia_vencida`, `garantia_por_vencer`
- `seguimiento_pendiente`
- `licitacion_proxima`
- `ampliacion_pendiente`
- `interaccion_programada`

### PATCH `/alertas/{alerta_id}/marcar-leida`
Mark alerta as read.

### PATCH `/alertas/{alerta_id}/marcar-resuelta`
Mark alerta as resolved with optional notes.

**Query Parameters:**
- `notas` (string): Optional resolution notes

### PUT `/alertas/{alerta_id}`
Update alerta (users can update their own alerts).

### DELETE `/alertas/{alerta_id}`
Delete alerta (coordinator role or higher).

### Configuración de Alertas

#### GET `/alertas/configuracion/me`
Get current user's alertas configuration.

If no configuration exists, creates one with default settings.

#### PUT `/alertas/configuracion/me`
Update current user's alertas configuration.

**Request:**
```json
{
  "alertas_documentos_vencidos": true,
  "dias_alerta_documentos": 15,
  "alertas_contratos_proximos": true,
  "dias_alerta_contratos": 30,
  "alertas_garantias": true,
  "dias_alerta_garantias": 15,
  "notificar_email": true,
  "enviar_resumen_diario": true
}
```

---

## Dashboard

### GET `/dashboard/stats`
Get general dashboard statistics.

**Query Parameters:**
- `fecha_desde` (date): Optional start date filter
- `fecha_hasta` (date): Optional end date filter

**Response:**
```json
{
  "total_clientes": 50,
  "total_licitaciones": 120,
  "licitaciones_activas": 35,
  "licitaciones_por_estado": {
    "en_preparacion": 15,
    "presentada": 20,
    "adjudicada": 50
  },
  "monto_total_ofertado": 50000000.00,
  "monto_total_adjudicado": 35000000.00,
  "tasa_exito": 70.5,
  "nuevas_licitaciones_mes": 12,
  "alertas_activas": 25,
  "alertas_criticas": 3,
  "licitaciones_proximas_15_dias": 8,
  "documentos_por_vencer_15_dias": 5,
  "top_clientes": [
    {
      "cliente_id": 1,
      "nombre_cliente": "Ministerio X",
      "total_licitaciones": 25
    }
  ]
}
```

### GET `/dashboard/activity`
Get recent activity in the system.

**Query Parameters:**
- `limit` (int): Maximum activities to return (default: 20, max: 100)

**Response:**
```json
{
  "total": 20,
  "activities": [
    {
      "tipo": "licitacion",
      "accion": "creada",
      "id": 123,
      "titulo": "Servicios de Consultoría",
      "fecha": "2025-01-14T10:30:00",
      "estado": "en_preparacion"
    }
  ]
}
```

---

## Status Codes

- `200 OK`: Successful request
- `201 Created`: Resource created successfully
- `204 No Content`: Successful deletion
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Authentication required or failed
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `422 Unprocessable Entity`: Validation error
- `500 Internal Server Error`: Server error

---

## Pagination Response Format

All paginated endpoints return:
```json
{
  "total": 100,
  "items": [...],
  "page": 1,
  "page_size": 20,
  "total_pages": 5
}
```

---

## Error Response Format

```json
{
  "detail": "Error message description"
}
```

For validation errors:
```json
{
  "detail": [
    {
      "loc": ["body", "field_name"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

---

## Interactive API Documentation

Access the interactive API documentation at:
- **Swagger UI**: http://localhost:8000/api/v1/docs
- **ReDoc**: http://localhost:8000/api/v1/redoc
