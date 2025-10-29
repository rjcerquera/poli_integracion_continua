# 💸 Expense Manager - Aplicación de Gestión de Gastos Personales

Aplicación web full-stack para la gestión de gastos personales con autenticación, categorización de gastos y visualización de estadísticas.

## 📋 Descripción

Sistema completo de gestión de gastos personales que permite a los usuarios:
- Registrarse e iniciar sesión de forma segura
- Crear y gestionar categorías personalizadas con iconos y colores
- Registrar gastos con fechas y descripciones
- Visualizar resúmenes y estadísticas de gastos
- Consultar documentación interactiva de la API

## 🚀 Tecnologías Utilizadas

### Backend
- **Laravel 12.x** - Framework PHP
- **Laravel Sanctum** - Autenticación API basada en tokens
- **MySQL 8.0** - Base de datos relacional
- **L5-Swagger** - Documentación OpenAPI/Swagger
- **PHP 8.2** - Lenguaje de programación
- **Nginx** - Servidor web

### Frontend
- **Next.js 16** - Framework React con App Router
- **React 19** - Biblioteca de interfaces de usuario
- **TypeScript** - Tipado estático
- **Tailwind CSS** - Framework de estilos
- **Context API** - Gestión de estado para autenticación

### DevOps
- **Docker & Docker Compose** - Containerización
- **Multi-stage builds** - Optimización de imágenes Docker

## 📦 Arquitectura

```
┌─────────────────┐
│   Frontend      │
│   Next.js       │
│   Port: 3000    │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│     Nginx       │
│   Port: 8080    │
└────────┬────────┘
         │
         ↓
┌─────────────────┐      ┌─────────────────┐
│   Backend       │◄────►│     MySQL       │
│   Laravel       │      │   Port: 3306    │
│   PHP-FPM       │      └─────────────────┘
└─────────────────┘
```

## 🛠️ Requisitos Previos

- Docker Engine 20.10+
- Docker Compose 2.0+
- Puertos disponibles: 3000, 8080, 3306

## 📥 Instalación y Configuración

### 1. Clonar el Repositorio

```bash
git clone <repository-url>
cd project
```

### 2. Configuración del Backend

Crear archivo `.env` en `app_backend/`:

```bash
cp app_backend/.env.example app_backend/.env
```

Configurar variables de entorno en `app_backend/.env`:

```env
APP_NAME="Expense Manager"
APP_ENV=production
APP_DEBUG=false
APP_URL=http://localhost:8080

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret

SANCTUM_STATEFUL_DOMAINS=localhost:3000
SESSION_DOMAIN=localhost
```

### 3. Construir y Levantar los Contenedores

```bash
# Construir las imágenes
docker-compose build

# Levantar los servicios
docker-compose up -d
```

### 4. Ejecutar Migraciones

```bash
docker-compose exec backend php artisan migrate
```

### 5. (Opcional) Sembrar Datos de Prueba

```bash
docker-compose exec backend php artisan db:seed
```

## 🎯 Uso

### Acceder a la Aplicación

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Documentación Swagger**: http://localhost:8080/api/documentation

### Flujo de Uso

1. **Registrar una cuenta** en http://localhost:3000/register
2. **Iniciar sesión** en http://localhost:3000/login
3. **Crear categorías** para organizar tus gastos
4. **Registrar gastos** con montos, fechas y categorías
5. **Visualizar estadísticas** en el dashboard

## 📡 Endpoints del API

### Autenticación

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/register` | Registrar nuevo usuario |
| POST | `/api/login` | Iniciar sesión |
| POST | `/api/logout` | Cerrar sesión |
| GET | `/api/me` | Obtener usuario autenticado |

#### Ejemplo: Registro

```bash
curl -X POST http://localhost:8080/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'
```

**Respuesta:**
```json
{
  "access_token": "1|abcdef123456...",
  "token_type": "Bearer",
  "user": {
    "id": 1,
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "created_at": "2025-10-29T10:00:00.000000Z",
    "updated_at": "2025-10-29T10:00:00.000000Z"
  }
}
```

### Categorías

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/categories` | Listar categorías del usuario |
| POST | `/api/categories` | Crear nueva categoría |
| PUT | `/api/categories/{id}` | Actualizar categoría |
| DELETE | `/api/categories/{id}` | Eliminar categoría |

#### Ejemplo: Crear Categoría

```bash
curl -X POST http://localhost:8080/api/categories \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "name": "Alimentación",
    "icon": "🍔",
    "color": "#10B981"
  }'
```

**Respuesta:**
```json
{
  "id": 1,
  "name": "Alimentación",
  "icon": "🍔",
  "color": "#10B981",
  "user_id": 1,
  "created_at": "2025-10-29T10:00:00.000000Z",
  "updated_at": "2025-10-29T10:00:00.000000Z"
}
```

### Gastos

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/expenses` | Listar gastos del usuario |
| POST | `/api/expenses` | Crear nuevo gasto |
| PUT | `/api/expenses/{id}` | Actualizar gasto |
| DELETE | `/api/expenses/{id}` | Eliminar gasto |
| GET | `/api/expenses-summary` | Obtener resumen de gastos |

#### Ejemplo: Crear Gasto

```bash
curl -X POST http://localhost:8080/api/expenses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "amount": 50.99,
    "description": "Compra en supermercado",
    "date": "2025-10-29",
    "category_id": 1
  }'
```

**Respuesta:**
```json
{
  "id": 1,
  "amount": 50.99,
  "description": "Compra en supermercado",
  "date": "2025-10-29",
  "category_id": 1,
  "user_id": 1,
  "category": {
    "id": 1,
    "name": "Alimentación",
    "icon": "🍔",
    "color": "#10B981"
  },
  "created_at": "2025-10-29T10:00:00.000000Z",
  "updated_at": "2025-10-29T10:00:00.000000Z"
}
```

#### Ejemplo: Obtener Resumen

```bash
curl -X GET http://localhost:8080/api/expenses-summary \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Respuesta:**
```json
{
  "total_expenses": 1250.50,
  "recent_expenses": 350.00,
  "expenses_by_category": [
    {
      "category": {
        "id": 1,
        "name": "Alimentación",
        "icon": "🍔",
        "color": "#10B981"
      },
      "total": 450.75
    },
    {
      "category": {
        "id": 2,
        "name": "Transporte",
        "icon": "🚗",
        "color": "#3B82F6"
      },
      "total": 200.50
    }
  ]
}
```

## 📁 Estructura del Proyecto

```
project/
├── app_backend/              # Aplicación Laravel
│   ├── app/
│   │   ├── Http/
│   │   │   └── Controllers/
│   │   │       └── Api/
│   │   │           ├── AuthController.php
│   │   │           ├── CategoryController.php
│   │   │           └── ExpenseController.php
│   │   └── Models/
│   │       ├── User.php
│   │       ├── Category.php
│   │       └── Expense.php
│   ├── database/
│   │   ├── migrations/
│   │   └── seeders/
│   ├── routes/
│   │   ├── api.php
│   │   └── web.php
│   └── config/
│       └── l5-swagger.php
│
├── app_frontend/             # Aplicación Next.js
│   ├── app/
│   │   ├── dashboard/
│   │   │   └── page.tsx
│   │   ├── expenses/
│   │   │   └── page.tsx
│   │   ├── categories/
│   │   │   └── page.tsx
│   │   ├── login/
│   │   │   └── page.tsx
│   │   └── register/
│   │       └── page.tsx
│   ├── components/
│   │   └── Navbar.tsx
│   ├── contexts/
│   │   └── AuthContext.tsx
│   └── lib/
│       └── api.ts
│
├── backend/                  # Configuración Docker Backend
│   ├── Dockerfile
│   └── entrypoint.sh
│
├── frontend/                 # Configuración Docker Frontend
│   └── Dockerfile
│
├── nginx/                    # Configuración Nginx
│   └── default.conf
│
└── docker-compose.yml        # Orquestación de contenedores
```

## ✨ Características

### Backend
- ✅ API RESTful con Laravel
- ✅ Autenticación JWT con Sanctum
- ✅ Validación de datos
- ✅ Relaciones de base de datos
- ✅ Documentación Swagger interactiva
- ✅ Middleware de autenticación
- ✅ Endpoints de estadísticas

### Frontend
- ✅ Interfaz de usuario moderna y responsive
- ✅ Autenticación persistente
- ✅ Navegación con App Router
- ✅ Gestión de estado con Context API
- ✅ Formularios interactivos
- ✅ Visualización de datos con Tailwind
- ✅ Selectores visuales de iconos y colores
- ✅ Formato de fechas y monedas

### DevOps
- ✅ Containerización completa con Docker
- ✅ Multi-stage builds para optimización
- ✅ Volúmenes persistentes para MySQL
- ✅ Red interna entre servicios
- ✅ Configuración de entorno separada

## 🔧 Comandos Útiles

### Docker

```bash
# Ver logs de los servicios
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f backend

# Reiniciar servicios
docker-compose restart

# Detener servicios
docker-compose down

# Detener y eliminar volúmenes
docker-compose down -v

# Reconstruir sin caché
docker-compose build --no-cache
```

### Laravel (Backend)

```bash
# Acceder al contenedor
docker-compose exec backend sh

# Ejecutar migraciones
docker-compose exec backend php artisan migrate

# Rollback de migraciones
docker-compose exec backend php artisan migrate:rollback

# Limpiar caché
docker-compose exec backend php artisan cache:clear
docker-compose exec backend php artisan config:clear

# Generar documentación Swagger
docker-compose exec backend php artisan l5-swagger:generate

# Crear modelo con migración
docker-compose exec backend php artisan make:model NombreModelo -m

# Crear controlador
docker-compose exec backend php artisan make:controller Api/NombreController
```

### Next.js (Frontend)

```bash
# Acceder al contenedor
docker-compose exec frontend sh

# Ver logs de build
docker-compose logs -f frontend
```

### Base de Datos

```bash
# Acceder a MySQL
docker-compose exec mysql mysql -u laravel -psecret laravel

# Backup de base de datos
docker-compose exec mysql mysqldump -u laravel -psecret laravel > backup.sql

# Restaurar backup
docker-compose exec -T mysql mysql -u laravel -psecret laravel < backup.sql
```

## 🐛 Solución de Problemas

### El backend no inicia
```bash
# Verificar logs
docker-compose logs backend

# Verificar permisos
docker-compose exec backend chmod -R 775 storage bootstrap/cache

# Regenerar clave de aplicación
docker-compose exec backend php artisan key:generate
```

### Error de conexión a MySQL
```bash
# Verificar que MySQL esté corriendo
docker-compose ps mysql

# Verificar credenciales en .env
docker-compose exec backend cat .env | grep DB_
```

### El frontend no conecta con el backend
```bash
# Verificar variable de entorno
docker-compose exec frontend printenv | grep NEXT_PUBLIC_API_URL

# Debe ser: NEXT_PUBLIC_API_URL=http://localhost:8080/api
```

### Problemas con migraciones
```bash
# Limpiar y volver a migrar
docker-compose exec backend php artisan migrate:fresh

# Con datos de prueba
docker-compose exec backend php artisan migrate:fresh --seed
```

## 📝 Variables de Entorno

### Backend (`app_backend/.env`)

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `APP_NAME` | Nombre de la aplicación | Expense Manager |
| `APP_ENV` | Entorno | production |
| `APP_DEBUG` | Modo debug | false |
| `APP_URL` | URL del backend | http://localhost:8080 |
| `DB_HOST` | Host de MySQL | mysql |
| `DB_DATABASE` | Nombre de BD | laravel |
| `DB_USERNAME` | Usuario de BD | laravel |
| `DB_PASSWORD` | Contraseña de BD | secret |

### Frontend (docker-compose.yml)

| Variable | Descripción | Valor |
|----------|-------------|-------|
| `NEXT_PUBLIC_API_URL` | URL del API | http://localhost:8080/api |


## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la Licencia MIT.


## 🙏 Agradecimientos

- Laravel Framework
- Next.js Team
- Tailwind CSS
- Docker Community

