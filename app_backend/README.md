# Expense Manager API - Backend

API RESTful desarrollada con Laravel 12 para la gestión de gastos personales.

## 📋 Descripción

Este backend proporciona una API completa para gestionar usuarios, categorías y gastos personales, con autenticación basada en tokens usando Laravel Sanctum.

## 🚀 Características

- ✅ API RESTful con Laravel
- ✅ Autenticación JWT con Sanctum
- ✅ Validación de datos
- ✅ Relaciones de base de datos
- ✅ Documentación Swagger interactiva
- ✅ Middleware de autenticación
- ✅ Endpoints de estadísticas
- ✅ Pruebas unitarias completas con PHPUnit
- ✅ Cobertura de código configurada

## 📦 Requisitos

- PHP 8.2 o superior
- Composer
- MySQL 8.0 o SQLite
- Laravel 12.x

## 🔧 Instalación

```bash
# Instalar dependencias
composer install

# Copiar archivo de entorno
cp .env.example .env

# Generar clave de aplicación
php artisan key:generate

# Ejecutar migraciones
php artisan migrate

# Generar documentación Swagger
php artisan l5-swagger:generate
```

## 🧪 Pruebas

### Ejecutar todas las pruebas

```bash
php artisan test
```

O usando PHPUnit directamente:

```bash
./vendor/bin/phpunit
```

### Ejecutar pruebas específicas

```bash
# Pruebas de autenticación
php artisan test --filter AuthTest

# Pruebas de categorías
php artisan test --filter CategoryTest

# Pruebas de gastos
php artisan test --filter ExpenseTest

# Pruebas unitarias de modelos
php artisan test --filter ExpenseModelTest
php artisan test --filter CategoryModelTest

# Solo pruebas de Feature
php artisan test --testsuite=Feature

# Solo pruebas unitarias
php artisan test --testsuite=Unit
```

### Cobertura de Código

**Nota**: Para generar reportes de cobertura, se requiere la extensión PCOV (ya incluida en el Dockerfile).

Para generar un reporte de cobertura de código en formato HTML:

```bash
./vendor/bin/phpunit --coverage-html coverage
```

El reporte se generará en el directorio `coverage/`. Abre `coverage/index.html` en tu navegador para ver el reporte completo.

Para ver un resumen de cobertura en la consola:

```bash
./vendor/bin/phpunit --coverage-text
```

**Cobertura actual**: Las pruebas alcanzan **100% de cobertura**:
- **Classes**: 100.00% (6/6 clases)
- **Methods**: 100.00% (22/22 métodos)
- **Lines**: 100.00% (135/135 líneas)

Cobertura completa por componente:
- **AuthController**: 100% métodos (4/4), 100% líneas (36/36)
- **CategoryController**: 100% métodos (5/5), 100% líneas (25/25)
- **ExpenseController**: 100% métodos (6/6), 100% líneas (64/64)
- **Category Model**: 100% métodos (2/2), 100% líneas (2/2)
- **Expense Model**: 100% métodos (2/2), 100% líneas (2/2)
- **User Model**: 100% métodos (3/3), 100% líneas (6/6)

### Estructura de Pruebas

Las pruebas están organizadas en dos directorios:

#### Pruebas de Feature (`tests/Feature/`)

- **AuthTest.php**: Pruebas para los endpoints de autenticación
  - `POST /api/register` - Registro de usuarios
  - `POST /api/login` - Inicio de sesión
  - `POST /api/logout` - Cierre de sesión
  - `GET /api/me` - Obtener perfil del usuario autenticado
  - `GET /api/user` - Obtener perfil del usuario autenticado (alternativa)

- **CategoryTest.php**: Pruebas para los endpoints de categorías
  - `GET /api/categories` - Listar categorías
  - `POST /api/categories` - Crear categoría
  - `GET /api/categories/{id}` - Ver categoría
  - `PUT /api/categories/{id}` - Actualizar categoría
  - `DELETE /api/categories/{id}` - Eliminar categoría

- **ExpenseTest.php**: Pruebas para los endpoints de gastos
  - `GET /api/expenses` - Listar gastos
  - `POST /api/expenses` - Crear gasto
  - `GET /api/expenses/{id}` - Ver gasto
  - `PUT /api/expenses/{id}` - Actualizar gasto
  - `DELETE /api/expenses/{id}` - Eliminar gasto
  - `GET /api/expenses-summary` - Resumen de gastos

#### Pruebas Unitarias (`tests/Unit/`)

- **ExpenseModelTest.php**: Pruebas unitarias del modelo Expense (3 pruebas)
  - Relación `belongsTo` con User
  - Relación `belongsTo` con Category
  - Validación de expense sin categoría

- **CategoryModelTest.php**: Pruebas unitarias del modelo Category (3 pruebas)
  - Relación `belongsTo` con User
  - Relación `hasMany` con Expense
  - Validación de category sin expenses

**Total**: 57 pruebas (51 Feature + 6 Unit) con 219 assertions

### Configuración de Pruebas

La configuración de PHPUnit se encuentra en `phpunit.xml`. La configuración actual incluye:

- Base de datos en memoria para pruebas (`DB_DATABASE=:memory:`)
- Entorno de pruebas (`APP_ENV=testing`)
- Configuración de cobertura de código
- Exclusión del directorio `app/Providers` de la cobertura

### Factories

Las factories utilizadas en las pruebas están en `database/factories/`:

- **UserFactory**: Para crear usuarios de prueba
- **CategoryFactory**: Para crear categorías de prueba
- **ExpenseFactory**: Para crear gastos de prueba

### Notas Importantes

1. Las pruebas utilizan `RefreshDatabase` para asegurar que cada prueba comience con una base de datos limpia.

2. Las pruebas de endpoints protegidos requieren autenticación mediante tokens Sanctum.

3. Las pruebas verifican tanto casos exitosos como casos de error (validación, autorización, etc.).

4. La cobertura de código incluye:
   - Controladores de la API (`app/Http/Controllers/Api/`)
   - Modelos y sus relaciones (`app/Models/`)
   - Validaciones y lógica de negocio

Para más detalles sobre las pruebas, consulta [TESTING.md](TESTING.md).

## 📚 Documentación de la API

La documentación interactiva de la API está disponible en Swagger UI. Una vez que el servidor esté ejecutándose:

```
http://localhost:8000/api/documentation
```

## 🔐 Endpoints Principales

### Autenticación
- `POST /api/register` - Registro de usuarios
- `POST /api/login` - Inicio de sesión
- `POST /api/logout` - Cierre de sesión
- `GET /api/me` - Obtener perfil del usuario autenticado

### Categorías (Protegido)
- `GET /api/categories` - Listar categorías del usuario
- `POST /api/categories` - Crear categoría
- `GET /api/categories/{id}` - Ver categoría
- `PUT /api/categories/{id}` - Actualizar categoría
- `DELETE /api/categories/{id}` - Eliminar categoría

### Gastos (Protegido)
- `GET /api/expenses` - Listar gastos del usuario
- `POST /api/expenses` - Crear gasto
- `GET /api/expenses/{id}` - Ver gasto
- `PUT /api/expenses/{id}` - Actualizar gasto
- `DELETE /api/expenses/{id}` - Eliminar gasto
- `GET /api/expenses-summary` - Resumen de gastos

## 🗄️ Base de Datos

### Migraciones

```bash
# Ejecutar migraciones
php artisan migrate

# Revertir última migración
php artisan migrate:rollback

# Ver estado de migraciones
php artisan migrate:status
```

### Seeders

```bash
# Ejecutar seeders
php artisan db:seed

# Ejecutar seeder específico
php artisan db:seed --class=CategorySeeder
```

## 🛠️ Comandos Útiles

```bash
# Limpiar caché
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Optimizar aplicación
php artisan optimize

# Generar documentación Swagger
php artisan l5-swagger:generate

# Crear modelo con migración
php artisan make:model NombreModelo -m

# Crear controlador
php artisan make:controller Api/NombreController
```

## 📁 Estructura del Proyecto

```
app_backend/
├── app/
│   ├── Http/
│   │   └── Controllers/
│   │       └── Api/
│   │           ├── AuthController.php
│   │           ├── CategoryController.php
│   │           └── ExpenseController.php
│   └── Models/
│       ├── User.php
│       ├── Category.php
│       └── Expense.php
├── database/
│   ├── factories/
│   ├── migrations/
│   └── seeders/
├── routes/
│   └── api.php
├── tests/
│   ├── Feature/
│   │   ├── AuthTest.php
│   │   ├── CategoryTest.php
│   │   └── ExpenseTest.php
│   └── Unit/
│       ├── ExpenseModelTest.php
│       └── CategoryModelTest.php
└── phpunit.xml
```

## 📝 Licencia

Este proyecto es parte de un proyecto académico de Integración Continua.
