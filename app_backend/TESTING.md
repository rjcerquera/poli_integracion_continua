# Guía de Pruebas Unitarias

Este documento describe en detalle cómo ejecutar las pruebas unitarias y verificar la cobertura de código para los endpoints de la API.

> **Nota**: Para una guía rápida, consulta la sección de [Pruebas en README.md](README.md#-pruebas).

## Estructura de Pruebas

Las pruebas están organizadas en dos directorios:

### Pruebas de Feature (`tests/Feature/`)

Pruebas de integración que verifican el comportamiento completo de los endpoints:

- **AuthTest.php**: Pruebas para los endpoints de autenticación (16 pruebas)
  - `POST /api/register` - Registro de usuarios
  - `POST /api/login` - Inicio de sesión
  - `POST /api/logout` - Cierre de sesión
  - `GET /api/me` - Obtener perfil del usuario autenticado
  - `GET /api/user` - Obtener perfil del usuario autenticado (alternativa)

- **CategoryTest.php**: Pruebas para los endpoints de categorías (13 pruebas)
  - `GET /api/categories` - Listar categorías
  - `POST /api/categories` - Crear categoría
  - `GET /api/categories/{id}` - Ver categoría
  - `PUT /api/categories/{id}` - Actualizar categoría
  - `DELETE /api/categories/{id}` - Eliminar categoría

- **ExpenseTest.php**: Pruebas para los endpoints de gastos (20 pruebas)
  - `GET /api/expenses` - Listar gastos
  - `POST /api/expenses` - Crear gasto
  - `GET /api/expenses/{id}` - Ver gasto
  - `PUT /api/expenses/{id}` - Actualizar gasto
  - `DELETE /api/expenses/{id}` - Eliminar gasto
  - `GET /api/expenses-summary` - Resumen de gastos

### Pruebas Unitarias (`tests/Unit/`)

Pruebas unitarias que verifican la lógica de los modelos y sus relaciones:

- **ExpenseModelTest.php**: Pruebas del modelo Expense (3 pruebas)
  - Relación `belongsTo` con User
  - Relación `belongsTo` con Category
  - Validación de expense sin categoría

- **CategoryModelTest.php**: Pruebas del modelo Category (3 pruebas)
  - Relación `belongsTo` con User
  - Relación `hasMany` con Expense
  - Validación de category sin expenses

**Total**: 57 pruebas (51 Feature + 6 Unit = 57 pruebas, 219 assertions)

## Ejecutar Pruebas

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

# Solo pruebas de Feature (integración)
php artisan test --testsuite=Feature

# Solo pruebas unitarias
php artisan test --testsuite=Unit
```

### Ejecutar una prueba específica

```bash
php artisan test --filter test_user_can_register_with_valid_data
php artisan test --filter test_expense_belongs_to_user
```

## Cobertura de Código

### Requisitos

Para generar reportes de cobertura, se requiere la extensión PCOV (ya incluida en el Dockerfile). Si ves el warning "No code coverage driver available", verifica que PCOV esté instalado:

```bash
php -m | grep pcov
```

### Generar reporte de cobertura

Para generar un reporte de cobertura de código en formato HTML:

```bash
./vendor/bin/phpunit --coverage-html coverage
```

El reporte se generará en el directorio `coverage/`. Abre `coverage/index.html` en tu navegador para ver el reporte completo con detalles línea por línea.

### Ver cobertura en consola

Para ver un resumen de cobertura en la consola:

```bash
./vendor/bin/phpunit --coverage-text
```

### Cobertura con filtro específico

Para ver cobertura solo de controladores:

```bash
./vendor/bin/phpunit --coverage-text --coverage-filter app/Http/Controllers
```

Para ver cobertura solo de modelos:

```bash
./vendor/bin/phpunit --coverage-text --coverage-filter app/Models
```

### Cobertura Actual

Con las pruebas implementadas, se alcanza **100% de cobertura de código**:

- **Classes**: 100.00% (6/6 clases)
  - `App\Http\Controllers\Api\AuthController`: 100% métodos (4/4), 100% líneas (36/36)
  - `App\Http\Controllers\Api\CategoryController`: 100% métodos (5/5), 100% líneas (25/25)
  - `App\Http\Controllers\Api\ExpenseController`: 100% métodos (6/6), 100% líneas (64/64)
  - `App\Models\Category`: 100% métodos (2/2), 100% líneas (2/2)
  - `App\Models\Expense`: 100% métodos (2/2), 100% líneas (2/2)
  - `App\Models\User`: 100% métodos (3/3), 100% líneas (6/6)

- **Methods**: 100.00% (22/22 métodos)
  - Todos los métodos de controladores cubiertos
  - Todas las relaciones de modelos cubiertas
  - Todos los métodos de modelos cubiertos

- **Lines**: 100.00% (135/135 líneas)
  - Cobertura completa de lógica de negocio
  - Casos de error y validación cubiertos
  - Todas las relaciones entre modelos probadas

## Configuración

La configuración de PHPUnit se encuentra en `phpunit.xml`. La configuración actual incluye:

- Base de datos en memoria para pruebas (`DB_DATABASE=:memory:`)
- Entorno de pruebas (`APP_ENV=testing`)
- Configuración de cobertura de código con PCOV
- Inclusión del directorio `app` para cobertura
- Exclusión del directorio `app/Providers` de la cobertura
- Reportes HTML y texto configurados automáticamente

## Factories

Las factories utilizadas en las pruebas están en `database/factories/`:

- **UserFactory**: Para crear usuarios de prueba
- **CategoryFactory**: Para crear categorías de prueba
- **ExpenseFactory**: Para crear gastos de prueba

## Notas Importantes

1. Las pruebas utilizan `RefreshDatabase` para asegurar que cada prueba comience con una base de datos limpia.

2. Las pruebas de endpoints protegidos requieren autenticación mediante tokens Sanctum.

3. Las pruebas verifican tanto casos exitosos como casos de error (validación, autorización, etc.).

4. La cobertura de código incluye:
   - Controladores de la API (`app/Http/Controllers/Api/`)
   - Modelos y sus relaciones (`app/Models/`)
   - Validaciones y lógica de negocio
   - Casos de éxito y error

## Ejemplo de Salida

Al ejecutar `php artisan test`, deberías ver una salida similar a esta:

```
PASS  Tests\Unit\CategoryModelTest
✓ category belongs to user
✓ category has many expenses
✓ category can have no expenses

PASS  Tests\Unit\ExampleTest
✓ that true is true

PASS  Tests\Unit\ExpenseModelTest
✓ expense belongs to user
✓ expense belongs to category
✓ expense can exist without category

PASS  Tests\Feature\AuthTest
✓ user can register with valid data
✓ user cannot register with invalid email
✓ user cannot register with duplicate email
✓ user cannot register with short password
✓ user cannot register with mismatched passwords
✓ user cannot register without required fields
✓ user can login with valid credentials
✓ user cannot login with invalid email
✓ user cannot login with invalid password
✓ user cannot login without credentials
✓ authenticated user can logout
✓ unauthenticated user cannot logout
✓ authenticated user can get profile via me
✓ unauthenticated user cannot get profile via me
✓ authenticated user can get profile via user
✓ unauthenticated user cannot get profile via user

PASS  Tests\Feature\CategoryTest
✓ authenticated user can list categories
✓ unauthenticated user cannot list categories
✓ authenticated user can create category
✓ authenticated user cannot create category without name
✓ authenticated user can create category with only name
✓ authenticated user can view own category
✓ authenticated user cannot view other user category
✓ authenticated user can update own category
✓ authenticated user can partially update category
✓ authenticated user cannot update other user category
✓ authenticated user can delete own category
✓ authenticated user cannot delete other user category
✓ unauthenticated user cannot create category

PASS  Tests\Feature\ExampleTest
✓ the application returns a successful response

PASS  Tests\Feature\ExpenseTest
✓ authenticated user can list expenses
✓ expenses are ordered by date descending
✓ unauthenticated user cannot list expenses
✓ authenticated user can create expense
✓ authenticated user can create expense with category
✓ authenticated user cannot create expense with other user category
✓ authenticated user cannot create expense without required fields
✓ authenticated user cannot create expense with negative amount
✓ authenticated user can view own expense
✓ authenticated user cannot view other user expense
✓ authenticated user can update own expense
✓ authenticated user can update expense category
✓ authenticated user cannot update expense with other user category
✓ authenticated user cannot update other user expense
✓ authenticated user can delete own expense
✓ authenticated user cannot delete other user expense
✓ authenticated user can get expenses summary
✓ expenses summary only includes user own expenses
✓ unauthenticated user cannot create expense
✓ unauthenticated user cannot get expenses summary

Tests:    57 passed (219 assertions)
Duration: 3.04s
```

## Mejora de Cobertura

Las pruebas unitarias de modelos (`ExpenseModelTest` y `CategoryModelTest`) fueron agregadas para mejorar la cobertura de código, específicamente:

- **Cobertura de relaciones**: Verifican que las relaciones `belongsTo` y `hasMany` funcionen correctamente
- **Cobertura de modelos**: Aseguran que los modelos Category y Expense estén completamente cubiertos
- **Casos edge**: Validan escenarios como expenses sin categoría y categories sin expenses

Esto eleva la cobertura de código de 67% a **100%** en clases, métodos y líneas, logrando cobertura completa del código de la API.

