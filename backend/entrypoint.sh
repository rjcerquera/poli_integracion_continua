#!/bin/bash

set -e

echo "🚀 Iniciando Laravel API..."

# Función para esperar a que MySQL esté listo
wait_for_mysql() {
    echo "⏳ Esperando a que MySQL esté disponible..."
    
    until php -r "new PDO('mysql:host=${DB_HOST};port=${DB_PORT};dbname=${DB_DATABASE}', '${DB_USERNAME}', '${DB_PASSWORD}');" &> /dev/null; do
        echo "⏳ MySQL no está listo todavía. Esperando..."
        sleep 2
    done
    
    echo "✅ MySQL está listo!"
}

# Función para ejecutar migraciones
run_migrations() {
    echo "🔄 Verificando y ejecutando migraciones..."
    
    if php artisan migrate --force; then
        echo "✅ Migraciones ejecutadas exitosamente"
    else
        echo "⚠️  Error al ejecutar migraciones"
    fi
}

# Función para ejecutar seeders (opcional)
run_seeders() {
    if [ "$RUN_SEEDERS" = "true" ]; then
        echo "🌱 Ejecutando seeders..."
        php artisan db:seed --force
        echo "✅ Seeders ejecutados"
    fi
}

echo "======================================"
echo "  Laravel API - Inicialización"
echo "======================================"
echo ""

# Paso 1: Esperar a MySQL
wait_for_mysql
echo ""

# Paso 2: Ejecutar migraciones
run_migrations
echo ""

# Paso 3: Ejecutar seeders (si está habilitado)
run_seeders
echo ""

echo "======================================"
echo "  ✅ Inicialización completada"
echo "======================================"
echo ""
echo "🚀 Iniciando PHP-FPM..."

# Ejecutar el comando pasado al contenedor (PHP-FPM)
exec "$@"

