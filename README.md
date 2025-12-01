# 🔄 Proyecto de Integración Continua (CI/CD)

Sistema completo de Integración Continua que integra una aplicación web full-stack (Expense Manager) con herramientas de DevOps para automatizar el ciclo de desarrollo, pruebas y despliegue.

## 📋 Descripción

Este proyecto demuestra una arquitectura completa de CI/CD que incluye:

### Aplicación Principal: Expense Manager
Aplicación web full-stack para la gestión de gastos personales que permite a los usuarios:
- Registrarse e iniciar sesión de forma segura
- Crear y gestionar categorías personalizadas con iconos y colores
- Registrar gastos con fechas y descripciones
- Visualizar resúmenes y estadísticas de gastos
- Consultar documentación interactiva de la API

### Infraestructura CI/CD
- **Gitea**: Servidor Git liviano para control de versiones
- **Jenkins**: Servidor de CI/CD con pipelines automatizados
- **Gitea Bootstrap**: Script de inicialización automática de Gitea
- **MailHog**: Servidor SMTP de desarrollo para capturar emails de notificaciones
- Integración completa entre Gitea y Jenkins con webhooks automáticos
- Pipelines automatizados: webhook-pipeline y health-check-pipeline

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

### DevOps & CI/CD
- **Docker & Docker Compose** - Containerización
- **Docker Compose Plugin v2** - Instalado en Jenkins para gestión de contenedores
- **Multi-stage builds** - Optimización de imágenes Docker
- **Gitea** - Servidor Git liviano para control de versiones
- **Jenkins** - Servidor de CI/CD con pipelines automatizados
- **Gitea Jenkins Plugin** - Integración nativa entre Gitea y Jenkins
- **Generic Webhook Trigger** - Plugin para recibir webhooks personalizados
- **MailHog** - Servidor SMTP de desarrollo para capturar emails
- **Docker-out-of-Docker (DooD)** - Patrón para ejecutar Docker desde contenedores

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
│   PHP-FPM       │      └────────┬────────┘
└─────────────────┘               │
                                  │
         ┌────────────────────────┴────────────────────────┐
         │                                                  │
         ↓                                                  ↓
┌─────────────────┐                              ┌─────────────────┐
│     Gitea      │                              │    Jenkins     │
│  Git Server     │◄───── Webhooks ─────────────►│   CI/CD Server  │
│  Port: 3001    │                              │   Port: 8081   │
└────────┬────────┘                              └────────┬────────┘
         │                                                 │
         │                                                 │
┌─────────────────┐                              ┌─────────────────┐
│ Gitea Bootstrap │                              │    MailHog     │
│  (Init Script)  │                              │  SMTP Server    │
└─────────────────┘                              │  Port: 8025     │
                                                  └─────────────────┘
```

### Componentes CI/CD

- **Gitea** (Puerto 3001): Servidor Git que almacena el código fuente
- **Jenkins** (Puerto 8081): Servidor CI/CD que ejecuta pipelines automatizados
- **Gitea Bootstrap**: Script de inicialización que configura Gitea automáticamente
- **MailHog** (Puerto 8025): Servidor SMTP de desarrollo que captura emails de notificaciones
- **Webhooks**: Integración automática entre Gitea y Jenkins para activar builds
- **Pipelines**: 
  - `webhook-pipeline`: Se activa automáticamente mediante webhooks de Gitea
  - `health-check-pipeline`: Verifica el estado del sistema CI/CD

Para más detalles sobre la configuración de Gitea, consulta [gitea-bootstrap/README.md](gitea-bootstrap/README.md).

Para más detalles sobre la configuración de Jenkins, consulta [jenkins/README.md](jenkins/README.md).

Para más detalles sobre los pipelines, consulta [jenkins/pipelines/README.md](jenkins/pipelines/README.md).

## 🛠️ Requisitos Previos

- Docker Engine 20.10+
- Docker Compose 2.0+
- Puertos disponibles: 3000, 8080, 3306, 3001, 8081, 2223, 50000, 8025
- Acceso al socket de Docker (`/var/run/docker.sock`) para DooD (Docker-out-of-Docker)

## 📥 Instalación y Configuración

### 1. Clonar el Repositorio

```bash
git clone <repository-url>
cd project
```

### 2. Configuración de Variables de Entorno

Crear archivo `.env` en la raíz del proyecto:

```bash
cp env.example .env
```

Editar `.env` y configurar las variables necesarias. Las más importantes:

```env
# Configuración de Gitea
GITEA_ADMIN_USER=admin
GITEA_ADMIN_PASSWORD=admin123
GITEA_ADMIN_EMAIL=admin@example.com
GITEA_HTTP_PORT=3001

# Configuración de Jenkins
JENKINS_ADMIN_ID=admin
JENKINS_ADMIN_PASSWORD=admin123
JENKINS_HTTP_PORT=8081

# Configuración del repositorio
GITEA_REPO_NAME=poli_integracion_continua
GITEA_REPO_PRIVATE=false
GITEA_AUTO_PUSH=true
```

Para más detalles sobre todas las variables disponibles, consulta `env.example`.

### 3. Configuración del Backend (Opcional)

Si deseas configurar el backend de Expense Manager, crear archivo `.env` en `app_backend/`:

```bash
cp app_backend/.env.example app_backend/.env
```

### 4. Construir y Levantar los Contenedores

```bash
# Construir las imágenes
docker-compose build

# Levantar los servicios
docker-compose up -d
```

### 5. Verificar Servicios CI/CD

Una vez levantados los contenedores, verifica que los servicios estén disponibles:

- **Gitea**: http://localhost:3001
  - Usuario admin: Configurado en `GITEA_ADMIN_USER` y `GITEA_ADMIN_PASSWORD`
  - El script `gitea-bootstrap` crea automáticamente el usuario admin y el repositorio

- **Jenkins**: http://localhost:8081
  - Usuario admin: Configurado en `JENKINS_ADMIN_ID` y `JENKINS_ADMIN_PASSWORD`
  - El pipeline `health-check-pipeline` se crea automáticamente

> **Nota**: El servicio `gitea-bootstrap` se ejecuta una sola vez al iniciar los contenedores y configura automáticamente Gitea (crea base de datos, usuario admin, usuario Jenkins, y repositorio).

### 6. (Opcional) Ejecutar Migraciones del Backend

Si estás usando el backend de Expense Manager:

```bash
docker-compose exec backend php artisan migrate
docker-compose exec backend php artisan db:seed
```

## 🎯 Uso

### Acceder a los Servicios

#### Aplicación Expense Manager
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Documentación Swagger**: http://localhost:8080/api/documentation

#### Servicios CI/CD
- **Gitea**: http://localhost:3001
  - Usuario admin: Configurado en `.env` (`GITEA_ADMIN_USER` / `GITEA_ADMIN_PASSWORD`)
  - Repositorio: Creado automáticamente por `gitea-bootstrap`
- **Jenkins**: http://localhost:8081
  - Usuario admin: Configurado en `.env` (`JENKINS_ADMIN_ID` / `JENKINS_ADMIN_PASSWORD`)
  - Pipelines: `webhook-pipeline` y `health-check-pipeline` creados automáticamente
- **MailHog**: http://localhost:8025
  - Interfaz web para ver emails capturados
  - Servidor SMTP: `localhost:1025` (desde el host) o `minio:1025` (dentro de Docker)

### Flujo de Uso de la Aplicación

1. **Registrar una cuenta** en http://localhost:3000/register
2. **Iniciar sesión** en http://localhost:3000/login
3. **Crear categorías** para organizar tus gastos
4. **Registrar gastos** con montos, fechas y categorías
5. **Visualizar estadísticas** en el dashboard

### Flujo de CI/CD

1. **Acceder a Gitea** y verificar que el repositorio fue creado
2. **Hacer push de código** al repositorio en Gitea
3. **Verificar en Jenkins** que el webhook activó el pipeline automáticamente
   - El `webhook-pipeline` se ejecuta automáticamente cuando hay un push
   - Construye y prueba la aplicación Laravel
   - Envía notificaciones por email
4. **Revisar notificaciones** en MailHog (http://localhost:8025)
5. **Ejecutar manualmente** el `health-check-pipeline` para validar la integración

Para más detalles sobre la configuración y uso de Gitea, consulta [gitea-bootstrap/README.md](gitea-bootstrap/README.md).

Para más detalles sobre la configuración y uso de Jenkins, consulta [jenkins/README.md](jenkins/README.md).

Para más detalles sobre los pipelines, consulta [jenkins/pipelines/README.md](jenkins/pipelines/README.md).

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
├── gitea-bootstrap/          # Inicialización automática de Gitea
│   ├── Dockerfile
│   ├── init-gitea-complete.sh
│   └── README.md            # 📖 Ver documentación detallada
│
├── jenkins/                  # Configuración Jenkins CI/CD
│   ├── Dockerfile
│   ├── jenkins.yaml         # Configuración as Code (JCasC)
│   ├── plugins.txt          # Plugins pre-instalados
│   ├── init-scripts/        # Scripts de inicialización
│   │   └── createPipeline.groovy
│   ├── pipelines/           # Pipelines de Jenkins
│   │   ├── README.md        # 📖 Documentación de pipelines
│   │   ├── webhook-pipeline/    # Pipeline activado por webhooks
│   │   │   └── Jenkinsfile
│   │   └── health-check-pipeline/  # Pipeline de verificación
│   │       └── Jenkinsfile
│   └── README.md            # 📖 Ver documentación detallada
│
├── docker-compose.yml        # Orquestación de contenedores
├── env.example              # Variables de entorno de ejemplo
└── README.md               # Este archivo
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

### DevOps & CI/CD
- ✅ Containerización completa con Docker
- ✅ Multi-stage builds para optimización
- ✅ Volúmenes persistentes para MySQL, Jenkins y Gitea
- ✅ Red interna entre servicios
- ✅ Configuración de entorno separada
- ✅ **Gitea**: Servidor Git con inicialización automática
- ✅ **Jenkins**: CI/CD con pipelines automatizados
- ✅ **Pipelines**: webhook-pipeline y health-check-pipeline
- ✅ **Integración Gitea-Jenkins**: Webhooks automáticos
- ✅ **MailHog**: Servidor SMTP de desarrollo para notificaciones
- ✅ **Docker-out-of-Docker (DooD)**: Ejecución de Docker desde contenedores
- ✅ **Docker Compose v2**: Instalado en Jenkins para gestión de contenedores
- ✅ **Configuración as Code**: Jenkins configurado mediante JCasC

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

### Gitea

```bash
# Ver logs de Gitea
docker-compose logs -f gitea

# Acceder al contenedor de Gitea
docker-compose exec gitea sh

# Reiniciar Gitea
docker-compose restart gitea

# Ver logs del proceso de inicialización
docker-compose logs gitea-bootstrap
```

Para más detalles sobre Gitea, consulta [gitea-bootstrap/README.md](gitea-bootstrap/README.md).

### Jenkins

```bash
# Ver logs de Jenkins
docker-compose logs -f jenkins

# Acceder al contenedor de Jenkins
docker-compose exec jenkins bash

# Reiniciar Jenkins
docker-compose restart jenkins

# Verificar plugins instalados
docker-compose exec jenkins ls /var/jenkins_home/plugins

# Verificar pipelines creados
docker-compose exec jenkins ls /var/jenkins_home/jobs
```

Para más detalles sobre Jenkins, consulta [jenkins/README.md](jenkins/README.md).

### MailHog

```bash
# Ver logs de MailHog
docker-compose logs -f minio

# Acceder a la interfaz web
# http://localhost:8025

# Verificar que está corriendo
docker ps | grep mailhog
```

**Nota**: MailHog captura todos los emails enviados por Jenkins. Accede a http://localhost:8025 para ver los emails capturados.

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

### Gitea no inicia o no se inicializa correctamente
```bash
# Ver logs del proceso de inicialización
docker-compose logs gitea-bootstrap

# Verificar que MySQL esté disponible
docker-compose ps mysql

# Re-ejecutar el proceso de inicialización (detener y volver a levantar)
docker-compose down
docker-compose up -d
```

Para más detalles sobre solución de problemas de Gitea, consulta la sección [Troubleshooting](gitea-bootstrap/README.md#-troubleshooting) en gitea-bootstrap/README.md.

### Jenkins no inicia o el pipeline no se ejecuta
```bash
# Ver logs de Jenkins
docker-compose logs jenkins

# Verificar que Gitea esté disponible
curl http://localhost:3001/api/v1/version

# Verificar configuración del plugin Gitea
docker-compose exec jenkins cat /var/jenkins_home/jenkins.yaml | grep -A 10 gitea
```

Para más detalles sobre solución de problemas de Jenkins, consulta la sección [Troubleshooting](jenkins/README.md#-troubleshooting) en jenkins/README.md.

## 📝 Variables de Entorno

Las variables de entorno principales se configuran en el archivo `.env` en la raíz del proyecto. Para ver todas las variables disponibles, consulta `env.example`.

### Variables Principales

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `GITEA_ADMIN_USER` | Usuario administrador de Gitea | admin |
| `GITEA_ADMIN_PASSWORD` | Contraseña del admin de Gitea | admin123 |
| `GITEA_HTTP_PORT` | Puerto externo de Gitea | 3001 |
| `JENKINS_ADMIN_ID` | Usuario administrador de Jenkins | admin |
| `JENKINS_ADMIN_PASSWORD` | Contraseña del admin de Jenkins | admin123 |
| `JENKINS_HTTP_PORT` | Puerto externo de Jenkins | 8081 |
| `GITEA_REPO_NAME` | Nombre del repositorio | poli_integracion_continua |
| `GITEA_REPO_PRIVATE` | Repositorio privado (true/false) | false |
| `GITEA_AUTO_PUSH` | Push automático del código | true |
| `SMTP_HOST` | Servidor SMTP (MailHog) | minio |
| `SMTP_PORT` | Puerto SMTP | 1025 |
| `SMTP_FROM` | Dirección de remitente | jenkins@localhost |
| `SMTP_TO` | Dirección de destinatario | admin@example.com |
| `MAILHOG_HTTP_PORT` | Puerto de la interfaz web de MailHog | 8025 |
| `MAILHOG_SMTP_PORT` | Puerto SMTP de MailHog | 1025 |

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

Para más detalles sobre las variables de entorno de Gitea, consulta la sección [Configuración](gitea-bootstrap/README.md#-configuración) en gitea-bootstrap/README.md.

Para más detalles sobre las variables de entorno de Jenkins, consulta la sección [Credenciales Parametrizables](jenkins/README.md#-credenciales-parametrizables) en jenkins/README.md.


## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la Licencia MIT.


## 📚 Documentación Adicional

- **[gitea-bootstrap/README.md](gitea-bootstrap/README.md)**: Documentación completa sobre la inicialización automática de Gitea, creación de usuarios, repositorios y el patrón Docker-out-of-Docker (DooD).
- **[jenkins/README.md](jenkins/README.md)**: Documentación completa sobre la configuración de Jenkins, pipelines, integración con Gitea, MailHog y el patrón Docker-out-of-Docker (DooD).
- **[jenkins/pipelines/README.md](jenkins/pipelines/README.md)**: Documentación detallada sobre los pipelines disponibles (webhook-pipeline y health-check-pipeline), su configuración y uso.

## 🙏 Agradecimientos

- Laravel Framework
- Next.js Team
- Tailwind CSS
- Docker Community
- Gitea Project
- Jenkins Project

