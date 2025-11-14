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
