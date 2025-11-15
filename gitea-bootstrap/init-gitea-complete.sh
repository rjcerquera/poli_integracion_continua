#!/bin/bash

# Gitea Complete Initialization Script
# Combina la inicialización de MySQL y la configuración de Gitea
# 1. Crea la base de datos MySQL para Gitea
# 2. Espera a que Gitea esté disponible
# 3. Crea usuario Jenkins
# 4. Crea repositorio
# 5. Hace push del código (opcional)

set -e

# Variables de entorno para MySQL
MYSQL_HOST="${MYSQL_HOST:-laravel_mysql}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root_password}"
GITEA_DB_NAME="${GITEA_DB_NAME:-gitea}"
GITEA_DB_USER="${GITEA_DB_USER:-gitea_user}"
GITEA_DB_PASSWORD="${GITEA_DB_PASSWORD:-gitea_password}"

# Variables de entorno para Gitea
# NOTA: GITEA_HOST debe ser el nombre del servicio en docker-compose (no el nombre del contenedor)
#       Dentro de la red Docker, los servicios se comunican usando el nombre del servicio
#       Por defecto: 'gitea' (nombre del servicio en docker-compose.yml)
GITEA_HOST="${GITEA_HOST:-gitea}"
GITEA_PORT="${GITEA_PORT:-3000}"
GITEA_URL="${GITEA_URL:-http://${GITEA_HOST}:${GITEA_PORT}}"
GITEA_CONTAINER_NAME="${GITEA_CONTAINER_NAME:-gitea_server}"
GITEA_ADMIN_USER="${GITEA_ADMIN_USER:-admin}"
GITEA_ADMIN_PASSWORD="${GITEA_ADMIN_PASSWORD:-admin123}"
GITEA_ADMIN_EMAIL="${GITEA_ADMIN_EMAIL:-admin@example.com}"
GITEA_REPO_OWNER="${GITEA_REPO_OWNER:-}"
GITEA_REPO_NAME="${GITEA_REPO_NAME:-poli_integracion_continua}"
GITEA_REPO_PRIVATE="${GITEA_REPO_PRIVATE:-true}"
GITEA_REPO_DESCRIPTION="${GITEA_REPO_DESCRIPTION:-Proyecto de Integración Continua}"

# Variables adicionales (pueden estar en uso en docker-compose.yml para configuración de Gitea)
# NOTA: Estas variables no se usan en este script, pero pueden ser necesarias para la configuración
#       de Gitea en docker-compose.yml
GITEA_DOMAIN="${GITEA_DOMAIN:-localhost}"
GITEA_ROOT_URL="${GITEA_ROOT_URL:-http://localhost:3001}"
GITEA_SSH_PORT="${GITEA_SSH_PORT:-2223}"
GITEA_DISABLE_REGISTRATION="${GITEA_DISABLE_REGISTRATION:-true}"

# Credenciales para usuario Jenkins
GITEA_JENKINS_USER="${GITEA_JENKINS_USER:-jenkins}"
GITEA_JENKINS_PASSWORD="${GITEA_JENKINS_PASSWORD:-jenkins123}"
GITEA_JENKINS_EMAIL="${GITEA_JENKINS_EMAIL:-jenkins@example.com}"

# Configuración para push automático
GITEA_AUTO_PUSH="${GITEA_AUTO_PUSH:-true}"
GITEA_REPO_PATH="${GITEA_REPO_PATH:-/workspace}"

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🚀 GITEA COMPLETE INITIALIZATION                              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# PASO 1: INICIALIZAR BASE DE DATOS MYSQL
# ============================================================================
echo -e "${GREEN}[Paso 1/4]${NC} Inicializando base de datos MySQL para Gitea..."

wait_for_mysql() {
    echo -e "${YELLOW}[MySQL Init]${NC} Esperando a que MySQL esté disponible..."
    echo -e "${YELLOW}[MySQL Init]${NC} Host: ${MYSQL_HOST}:${MYSQL_PORT}"
    echo -e "${YELLOW}[MySQL Init]${NC} Verificando conectividad de red..."
    
    # Mostrar información de debug
    echo -e "${YELLOW}[MySQL Init]${NC} Información de debug:"
    echo -e "${YELLOW}[MySQL Init]${NC}   - MYSQL_HOST=${MYSQL_HOST}"
    echo -e "${YELLOW}[MySQL Init]${NC}   - MYSQL_PORT=${MYSQL_PORT}"
    echo -e "${YELLOW}[MySQL Init]${NC}   - Intentando resolver hostname..."
    
    # Intentar resolver el hostname
    if command -v getent &> /dev/null || command -v nslookup &> /dev/null; then
        if command -v getent &> /dev/null; then
            getent hosts "${MYSQL_HOST}" || echo -e "${YELLOW}[MySQL Init]${NC}   - No se pudo resolver con getent"
        elif command -v nslookup &> /dev/null; then
            nslookup "${MYSQL_HOST}" || echo -e "${YELLOW}[MySQL Init]${NC}   - No se pudo resolver con nslookup"
        fi
    fi
    
    local max_attempts=60
    local attempt=0
    
    # Instalar herramientas necesarias si no están disponibles
    if ! command -v nc &> /dev/null && ! command -v mysqladmin &> /dev/null; then
        echo -e "${YELLOW}[MySQL Init]${NC} Instalando herramientas de red..."
        apk add --no-cache netcat-openbsd mysql-client > /dev/null 2>&1 || true
    fi
    
    while [ $attempt -lt $max_attempts ]; do
        # Intentar múltiples métodos de verificación
        
        # Método 1: netcat (nc) para verificar conexión TCP
        if command -v nc &> /dev/null; then
            if nc -z -w 2 "${MYSQL_HOST}" "${MYSQL_PORT}" 2>/dev/null; then
                echo -e "${GREEN}[MySQL Init]${NC} ✓ Puerto ${MYSQL_PORT} accesible en ${MYSQL_HOST}"
                # Si el puerto está abierto, intentar mysqladmin para confirmar
        if command -v mysqladmin &> /dev/null; then
            if mysqladmin ping -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u root -p"${MYSQL_ROOT_PASSWORD}" --ssl=0 --silent 2>/dev/null; then
                echo -e "${GREEN}[MySQL Init]${NC} ✓ MySQL está disponible y respondiendo!"
                return 0
            else
                echo -e "${YELLOW}[MySQL Init]${NC} Puerto abierto pero MySQL aún no responde completamente..."
            fi
        else
            # Si nc funciona pero no hay mysqladmin, asumir que está listo
            echo -e "${GREEN}[MySQL Init]${NC} ✓ Puerto MySQL accesible (asumiendo que MySQL está listo)"
            return 0
        fi
            fi
        fi
        
        # Método 2: timeout con /dev/tcp (bash builtin)
        if command -v timeout &> /dev/null && command -v bash &> /dev/null; then
            if timeout 2 bash -c "cat < /dev/null > /dev/tcp/${MYSQL_HOST}/${MYSQL_PORT}" 2>/dev/null; then
                echo -e "${GREEN}[MySQL Init]${NC} ✓ Conexión TCP exitosa a ${MYSQL_HOST}:${MYSQL_PORT}"
                return 0
            fi
        fi
        
        # Método 3: mysqladmin directo (si está disponible)
        if command -v mysqladmin &> /dev/null; then
            if mysqladmin ping -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u root -p"${MYSQL_ROOT_PASSWORD}" --ssl=0 --silent 2>/dev/null; then
                echo -e "${GREEN}[MySQL Init]${NC} ✓ MySQL está disponible!"
                return 0
            fi
        fi
        
        # Verificar resolución DNS
        if [ $attempt -eq 0 ]; then
            if ! getent hosts "${MYSQL_HOST}" > /dev/null 2>&1 && ! ping -c 1 -W 2 "${MYSQL_HOST}" > /dev/null 2>&1; then
                echo -e "${RED}[MySQL Init]${NC} ⚠ No se puede resolver el hostname: ${MYSQL_HOST}"
                echo -e "${YELLOW}[MySQL Init]${NC} ℹ️  Verifica que el contenedor MySQL esté en la misma red Docker"
            fi
        fi
        
        attempt=$((attempt + 1))
        if [ $((attempt % 5)) -eq 0 ]; then
            echo -e "${YELLOW}[MySQL Init]${NC} Intento $attempt/$max_attempts - Esperando MySQL en ${MYSQL_HOST}:${MYSQL_PORT}..."
        fi
        sleep 2
    done
    
    echo -e "${RED}[MySQL Init]${NC} ✗ Error: MySQL no está disponible después de $max_attempts intentos"
    echo -e "${RED}[MySQL Init]${NC} ℹ️  Verifica que:"
    echo -e "${RED}[MySQL Init]${NC}    - El contenedor MySQL esté corriendo: docker ps | grep mysql"
    echo -e "${RED}[MySQL Init]${NC}    - El hostname '${MYSQL_HOST}' sea correcto"
    echo -e "${RED}[MySQL Init]${NC}    - Los contenedores estén en la misma red Docker"
    return 1
}

create_gitea_database() {
    echo -e "${YELLOW}[MySQL Init]${NC} Creando base de datos y usuario para Gitea..."
    
    # Instalar mysql-client si no está disponible
    if ! command -v mysql &> /dev/null; then
        echo -e "${YELLOW}[MySQL Init]${NC} Instalando mysql-client..."
        if command -v apt-get &> /dev/null; then
            apt-get update -qq && apt-get install -y -qq default-mysql-client > /dev/null 2>&1 || true
        elif command -v apk &> /dev/null; then
            apk add --no-cache mysql-client > /dev/null 2>&1 || true
        fi
    fi
    
    if ! command -v mysql &> /dev/null; then
        echo -e "${YELLOW}[MySQL Init]${NC} ⚠ MySQL client no disponible. Saltando inicialización de BD."
        echo -e "${YELLOW}[MySQL Init]${NC} ℹ️  La base de datos debe crearse manualmente."
        return 0
    fi
    
    echo -e "${YELLOW}[MySQL Init]${NC} Ejecutando comandos SQL..."
    
    mysql -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u root -p"${MYSQL_ROOT_PASSWORD}" --ssl=0 <<EOF 2>&1
-- Crear base de datos si no existe
CREATE DATABASE IF NOT EXISTS \`${GITEA_DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Crear usuario si no existe
CREATE USER IF NOT EXISTS '${GITEA_DB_USER}'@'%' IDENTIFIED BY '${GITEA_DB_PASSWORD}';

-- Otorgar permisos
GRANT ALL PRIVILEGES ON \`${GITEA_DB_NAME}\`.* TO '${GITEA_DB_USER}'@'%';

-- Aplicar cambios
FLUSH PRIVILEGES;
EOF

    local mysql_exit=$?
    
    if [ $mysql_exit -eq 0 ]; then
        echo -e "${GREEN}[MySQL Init]${NC} ✓ Base de datos '${GITEA_DB_NAME}' creada exitosamente"
        echo -e "${GREEN}[MySQL Init]${NC} ✓ Usuario '${GITEA_DB_USER}' creado exitosamente"
        echo -e "${GREEN}[MySQL Init]${NC} ✓ Permisos otorgados correctamente"
        return 0
    else
        echo -e "${YELLOW}[MySQL Init]${NC} ⚠ Error al ejecutar comandos SQL (código: $mysql_exit)"
        echo -e "${YELLOW}[MySQL Init]${NC} ℹ️  Esto puede ser normal si la base de datos ya existe"
        return 0
    fi
}

# ============================================================================
# EJECUTAR INICIALIZACIÓN DE MYSQL PRIMERO (ANTES DE ESPERAR A GITEA)
# ============================================================================
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[Paso 1/4] INICIALIZACIÓN DE BASE DE DATOS MYSQL${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Paso 1.1: Esperar a que MySQL esté disponible
echo -e "${YELLOW}[1.1]${NC} Esperando a que MySQL esté disponible..."
wait_for_mysql || {
    echo -e "${RED}[MySQL Init]${NC} ✗ No se pudo conectar a MySQL"
    echo -e "${RED}[MySQL Init]${NC} ✗ No se puede continuar sin MySQL"
    exit 1
}

echo ""

# Paso 1.2: Crear base de datos y usuario para Gitea
echo -e "${YELLOW}[1.2]${NC} Creando base de datos y usuario para Gitea..."
create_gitea_database || {
    echo -e "${RED}[MySQL Init]${NC} ✗ Error crítico al crear la base de datos"
    echo -e "${RED}[MySQL Init]${NC} ✗ No se puede continuar sin la base de datos"
    exit 1
}

echo ""

# Paso 1.3: Verificar que la base de datos fue creada correctamente
echo -e "${YELLOW}[1.3]${NC} Verificando que la base de datos existe..."
verify_database_exists() {
    if ! command -v mysql &> /dev/null; then
        echo -e "${YELLOW}[MySQL Init]${NC} ⚠ MySQL client no disponible. No se puede verificar."
        return 0
    fi
    
    local db_exists=$(mysql -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u root -p"${MYSQL_ROOT_PASSWORD}" --ssl=0 \
        -e "SELECT COUNT(*) FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='${GITEA_DB_NAME}';" \
        -s -N 2>/dev/null || echo "0")
    
    if [ "$db_exists" = "1" ]; then
        echo -e "${GREEN}[MySQL Init]${NC} ✓ Base de datos '${GITEA_DB_NAME}' existe"
        return 0
    else
        echo -e "${RED}[MySQL Init]${NC} ✗ Base de datos '${GITEA_DB_NAME}' NO existe"
        return 1
    fi
}

verify_database_exists || {
    echo -e "${RED}[MySQL Init]${NC} ✗ La base de datos no se creó correctamente"
    exit 1
}

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[Paso 1/4] ✓ BASE DE DATOS MYSQL LISTA${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Resumen de base de datos creada:${NC}"
echo -e "   Base de datos: ${GITEA_DB_NAME}"
echo -e "   Usuario: ${GITEA_DB_USER}"
echo -e "   Host: ${MYSQL_HOST}:${MYSQL_PORT}"
echo ""

# ============================================================================
# PASO 2: ESPERAR A QUE GITEA ESTÉ DISPONIBLE
# ============================================================================
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[Paso 2/4] ESPERANDO A QUE GITEA ESTÉ DISPONIBLE${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}[Gitea Init]${NC} NOTA IMPORTANTE:"
echo -e "${YELLOW}[Gitea Init]${NC}   - La base de datos MySQL ya está creada y lista"
echo -e "${YELLOW}[Gitea Init]${NC}   - Esperando a que Gitea esté disponible y la API responda"
echo ""

wait_for_gitea() {
    echo -e "${YELLOW}[Gitea Init]${NC} Esperando a que Gitea esté disponible..."
    local max_attempts=120
    local attempt=0
    
    # Esperar a que Gitea responda en la URL base
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f "${GITEA_URL}" > /dev/null 2>&1; then
            echo -e "${GREEN}[Gitea Init]${NC} ✓ Gitea está respondiendo"
            break
        fi
        attempt=$((attempt + 1))
        if [ $((attempt % 10)) -eq 0 ]; then
            echo -e "${YELLOW}[Gitea Init]${NC} Intento $attempt/$max_attempts - Esperando a que Gitea responda..."
        fi
        sleep 2
    done
    
    if [ $attempt -ge $max_attempts ]; then
        echo -e "${RED}[Gitea Init]${NC} ✗ Gitea no responde después de $max_attempts intentos"
        echo -e "${RED}[Gitea Init]${NC} ℹ️  Verifica que:"
        echo -e "${RED}[Gitea Init]${NC}    - El contenedor de Gitea esté corriendo"
        echo -e "${RED}[Gitea Init]${NC}    - Gitea esté instalado y configurado"
        echo -e "${RED}[Gitea Init]${NC}    - La URL ${GITEA_URL} sea accesible"
        return 1
    fi
    
    # Esperar a que la API de Gitea esté disponible (indica que está instalado y funcionando)
    echo -e "${YELLOW}[Gitea Init]${NC} Verificando que la API de Gitea esté disponible..."
    attempt=0
    while [ $attempt -lt 60 ]; do
        if curl -s -f "${GITEA_URL}/api/v1/version" > /dev/null 2>&1; then
            echo -e "${GREEN}[Gitea Init]${NC} ✓ API de Gitea está disponible"
            return 0
        fi
        attempt=$((attempt + 1))
        if [ $((attempt % 10)) -eq 0 ]; then
            echo -e "${YELLOW}[Gitea Init]${NC} Intento $attempt/60 - Esperando a que la API de Gitea esté disponible..."
        fi
        sleep 2
    done
    
    echo -e "${RED}[Gitea Init]${NC} ✗ La API de Gitea no está disponible después de 60 intentos"
    echo -e "${RED}[Gitea Init]${NC} ℹ️  Verifica que Gitea esté completamente instalado y configurado"
    return 1
}

wait_for_gitea || exit 1
echo ""

# ============================================================================
# PASO 3: CREAR O VERIFICAR USUARIO ADMIN
# ============================================================================
echo -e "${GREEN}[Paso 3/4]${NC} Creando o verificando usuario admin en Gitea..."

# Función para verificar si el usuario admin existe
admin_user_exists() {
    local admin_user=$1
    local admin_password=$2
    
    local response=$(curl -s -w "\n%{http_code}" -X GET "${GITEA_URL}/api/v1/user" \
        -u "${admin_user}:${admin_password}" 2>/dev/null)
    
    local http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "200" ]; then
        return 0  # Usuario existe y credenciales son válidas
    fi
    return 1  # Usuario no existe o credenciales incorrectas
}

# Función para crear usuario admin usando la CLI de Gitea
create_admin_user_cli() {
    local admin_user=$1
    local admin_password=$2
    local admin_email=$3
    local container_name=$4
    
    echo -e "${YELLOW}[Gitea Init]${NC} Creando usuario admin usando CLI de Gitea..."
    echo -e "${YELLOW}[Gitea Init]${NC} Comando: su git -c \"gitea admin user create --admin --username ${admin_user} --password <hidden> --email ${admin_email}\""
    
    # Intentar usar docker exec si está disponible
    if command -v docker &> /dev/null; then
        echo -e "${YELLOW}[Gitea Init]${NC} Usando 'docker exec' para ejecutar comando en contenedor ${container_name}..."
        echo -e "${YELLOW}[Gitea Init]${NC} NOTA: Ejecutando como usuario 'git' (Gitea no puede ejecutarse como root)"
        
        # IMPORTANTE: Gitea debe ejecutarse como usuario 'git', no como root
        # Usar 'su git -c' para ejecutar el comando como usuario git
        local gitea_cmd="gitea admin user create --admin --username ${admin_user} --password ${admin_password} --email ${admin_email}"
        local docker_cmd="docker exec ${container_name} su git -c \"${gitea_cmd}\""
        
        local output=$(eval "$docker_cmd" 2>&1)
        local exit_code=$?
        
        # Mostrar output para debugging
        if [ -n "$output" ]; then
            echo -e "${YELLOW}[Gitea Init]${NC} Output del comando: $output"
        fi
        
        if [ $exit_code -eq 0 ]; then
            # Verificar que el mensaje de éxito esté en el output
            if echo "$output" | grep -qi "successfully created\|has been successfully created"; then
                echo -e "${GREEN}[Gitea Init]${NC} ✓ Usuario admin creado exitosamente usando CLI"
                return 0
            else
                # Si no hay mensaje de éxito pero el comando terminó con código 0, verificar si ya existe
                if echo "$output" | grep -qi "already exists\|user.*exists\|already registered"; then
                    echo -e "${YELLOW}[Gitea Init]${NC} ⚠ El usuario admin ya existe"
                    return 0
                else
                    echo -e "${YELLOW}[Gitea Init]${NC} ⚠ Comando completado pero no se detectó mensaje de éxito"
                    echo -e "${YELLOW}[Gitea Init]${NC} Output: $output"
                    return 1
                fi
            fi
        else
            # Si el usuario ya existe, eso está bien
            if echo "$output" | grep -qi "already exists\|user.*exists\|already registered"; then
                echo -e "${YELLOW}[Gitea Init]${NC} ⚠ El usuario admin ya existe"
                return 0
            else
                echo -e "${RED}[Gitea Init]${NC} ✗ Error al crear usuario con CLI (código: $exit_code)"
                echo -e "${YELLOW}[Gitea Init]${NC} Output: $output"
                return 1
            fi
        fi
    else
        echo -e "${YELLOW}[Gitea Init]${NC} ⚠ Docker no está disponible, no se puede usar CLI directamente"
        return 1
    fi
}

# Función para crear usuario admin usando la API REST (fallback)
create_admin_user_api() {
    local admin_user=$1
    local admin_password=$2
    local admin_email=$3
    
    echo -e "${YELLOW}[Gitea Init]${NC} Intentando crear usuario admin usando API REST..."
    
    # Nota: Para crear un usuario admin vía API, necesitamos estar autenticados como admin
    # Si no hay admin, necesitamos usar el primer usuario o crear uno sin autenticación
    # Esto solo funciona si Gitea permite crear el primer usuario sin autenticación
    
    local response=$(curl -s -w "\n%{http_code}" -X POST "${GITEA_URL}/api/v1/admin/users" \
        -H "Content-Type: application/json" \
        -d "{
            \"username\": \"${admin_user}\",
            \"email\": \"${admin_email}\",
            \"password\": \"${admin_password}\",
            \"must_change_password\": false,
            \"send_notify\": false,
            \"source_id\": 0,
            \"admin\": true
        }" 2>/dev/null)
    
    local http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "201" ]; then
        echo -e "${GREEN}[Gitea Init]${NC} ✓ Usuario admin creado exitosamente usando API"
        return 0
    elif [ "$http_code" = "422" ] || [ "$http_code" = "409" ]; then
        echo -e "${YELLOW}[Gitea Init]${NC} ⚠ El usuario admin ya existe"
        return 0
    else
        echo -e "${YELLOW}[Gitea Init]${NC} ⚠ No se pudo crear usuario con API (HTTP $http_code)"
        return 1
    fi
}

# Verificar si el usuario admin ya existe
if admin_user_exists "$GITEA_ADMIN_USER" "$GITEA_ADMIN_PASSWORD"; then
    echo -e "${GREEN}[Gitea Init]${NC} ✓ Usuario admin ya existe y credenciales son válidas"
else
    echo -e "${YELLOW}[Gitea Init]${NC} El usuario admin no existe o las credenciales no son válidas"
    echo -e "${YELLOW}[Gitea Init]${NC} Intentando crear usuario admin..."
    
    # Intentar crear usando CLI primero
    if ! create_admin_user_cli "$GITEA_ADMIN_USER" "$GITEA_ADMIN_PASSWORD" "$GITEA_ADMIN_EMAIL" "$GITEA_CONTAINER_NAME"; then
        # Si falla, intentar con API (puede que no funcione si no hay admin previo)
        echo -e "${YELLOW}[Gitea Init]${NC} CLI falló, intentando con API REST..."
        create_admin_user_api "$GITEA_ADMIN_USER" "$GITEA_ADMIN_PASSWORD" "$GITEA_ADMIN_EMAIL" || {
            echo -e "${RED}[Gitea Init]${NC} ✗ No se pudo crear el usuario admin"
            echo -e "${YELLOW}[Gitea Init]${NC} ℹ️  El usuario admin debe crearse manualmente o mediante variables de entorno GITEA__admin__*"
            echo -e "${YELLOW}[Gitea Init]${NC} ℹ️  Verifica que Gitea esté instalado y configurado correctamente"
        }
    fi
    
    # Verificar nuevamente después de intentar crear
    # Dar más tiempo para que Gitea procese la creación del usuario
    echo -e "${YELLOW}[Gitea Init]${NC} Esperando a que el usuario admin esté disponible..."
    verify_attempts=0
    max_verify_attempts=15
    
    while [ $verify_attempts -lt $max_verify_attempts ]; do
        sleep 2
        if admin_user_exists "$GITEA_ADMIN_USER" "$GITEA_ADMIN_PASSWORD"; then
            echo -e "${GREEN}[Gitea Init]${NC} ✓ Usuario admin creado y verificado exitosamente"
            break
        fi
        verify_attempts=$((verify_attempts + 1))
        if [ $((verify_attempts % 3)) -eq 0 ]; then
            echo -e "${YELLOW}[Gitea Init]${NC} Verificando usuario admin... (intento $verify_attempts/$max_verify_attempts)"
        fi
    done
    
    if [ $verify_attempts -ge $max_verify_attempts ]; then
        echo -e "${RED}[Gitea Init]${NC} ✗ No se pudo verificar el usuario admin después de $max_verify_attempts intentos"
        echo -e "${YELLOW}[Gitea Init]${NC} ℹ️  El usuario puede haber sido creado pero aún no está disponible"
        echo -e "${YELLOW}[Gitea Init]${NC} ℹ️  Verifica manualmente: docker exec ${GITEA_CONTAINER_NAME} su git -c 'gitea admin user list'"
        echo -e "${YELLOW}[Gitea Init]${NC} ℹ️  Continuando con la suposición de que el usuario existe..."
    fi
fi

echo ""

# ============================================================================
# PASO 4: CREAR USUARIO JENKINS Y REPOSITORIO
# ============================================================================
echo -e "${GREEN}[Paso 4/4]${NC} Configurando usuarios y repositorios en Gitea..."

# Si GITEA_REPO_OWNER no está configurado, usar el usuario admin
if [ -z "$GITEA_REPO_OWNER" ]; then
    GITEA_REPO_OWNER="${GITEA_ADMIN_USER}"
    echo -e "${GREEN}[Gitea Init]${NC} Usando usuario admin: ${GITEA_REPO_OWNER}"
fi

# Funciones para verificar existencia
user_exists() {
    local username=$1
    local admin_user=$2
    local admin_password=$3
    
    local response=$(curl -s -o /dev/null -w "%{http_code}" \
        -u "${admin_user}:${admin_password}" \
        "${GITEA_URL}/api/v1/users/${username}")
    
    [ "$response" = "200" ]
}

repo_exists() {
    local owner=$1
    local repo=$2
    local admin_user=$3
    local admin_password=$4
    
    local response=$(curl -s -o /dev/null -w "%{http_code}" \
        -u "${admin_user}:${admin_password}" \
        "${GITEA_URL}/api/v1/repos/${owner}/${repo}")
    
    [ "$response" = "200" ]
}

# Crear usuario Jenkins
create_jenkins_user() {
    local username=$1
    local password=$2
    local email=$3
    local admin_user=$4
    local admin_password=$5
    
    echo -e "${YELLOW}[Gitea Init]${NC} Verificando usuario Jenkins: ${username}..."
    
    if user_exists "$username" "$admin_user" "$admin_password"; then
        echo -e "${YELLOW}[Gitea Init]${NC} ⚠ El usuario ${username} ya existe, omitiendo creación."
        return 0
    fi
    
    echo -e "${YELLOW}[Gitea Init]${NC} Creando usuario Jenkins: ${username}..."
    
    local response=$(curl -s -w "\n%{http_code}" -X POST "${GITEA_URL}/api/v1/admin/users" \
        -u "${admin_user}:${admin_password}" \
        -H "Content-Type: application/json" \
        -d "{
            \"username\": \"${username}\",
            \"email\": \"${email}\",
            \"password\": \"${password}\",
            \"must_change_password\": false,
            \"send_notify\": false,
            \"source_id\": 0
        }")
    
    local http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "201" ]; then
        echo -e "${GREEN}[Gitea Init]${NC} ✓ Usuario Jenkins creado exitosamente!"
        return 0
    elif [ "$http_code" = "422" ]; then
        echo -e "${YELLOW}[Gitea Init]${NC} ⚠ El usuario ya existe o hay un conflicto."
        return 0
    else
        echo -e "${RED}[Gitea Init]${NC} ✗ Error al crear usuario Jenkins (HTTP $http_code)"
        return 1
    fi
}

# Crear repositorio
create_repository() {
    local owner=$1
    local repo=$2
    local private=$3
    local description=$4
    local admin_user=$5
    local admin_password=$6
    
    echo -e "${YELLOW}[Gitea Init]${NC} Verificando repositorio: ${owner}/${repo}..."
    
    if repo_exists "$owner" "$repo" "$admin_user" "$admin_password"; then
        echo -e "${YELLOW}[Gitea Init]${NC} ⚠ El repositorio ${owner}/${repo} ya existe."
        return 0
    fi
    
    echo -e "${YELLOW}[Gitea Init]${NC} Creando repositorio: ${owner}/${repo}..."
    
    local private_str="false"
    if [ "$private" = "true" ]; then
        private_str="true"
    fi
    
    local response=$(curl -s -w "\n%{http_code}" -X POST "${GITEA_URL}/api/v1/user/repos" \
        -u "${admin_user}:${admin_password}" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"${repo}\",
            \"description\": \"${description}\",
            \"private\": ${private_str},
            \"auto_init\": false
        }")
    
    local http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "201" ]; then
        echo -e "${GREEN}[Gitea Init]${NC} ✓ Repositorio creado exitosamente!"
        echo -e "${GREEN}[Gitea Init]${NC} URL: ${GITEA_URL}/${owner}/${repo}"
        return 0
    elif [ "$http_code" = "409" ]; then
        echo -e "${YELLOW}[Gitea Init]${NC} ⚠ El repositorio ya existe, omitiendo creación."
        return 0
    else
        echo -e "${RED}[Gitea Init]${NC} ✗ Error al crear repositorio (HTTP $http_code)"
        return 1
    fi
}

# Push automático del código
push_local_repository() {
    local admin_user=$1
    local admin_password=$2
    
    if [ "$GITEA_AUTO_PUSH" = "false" ]; then
        echo -e "${YELLOW}[Gitea Init]${NC} ℹ️  Push automático deshabilitado (GITEA_AUTO_PUSH=false)"
        return 0
    fi
    
    echo -e "${YELLOW}[Gitea Init]${NC} Intentando push automático del repositorio local..."
    echo -e "${YELLOW}[Gitea Init]${NC} Directorio: ${GITEA_REPO_PATH}"
    
    if [ ! -d "$GITEA_REPO_PATH" ] || [ ! -d "${GITEA_REPO_PATH}/.git" ]; then
        echo -e "${YELLOW}[Gitea Init]${NC} ⚠ No se encontró repositorio git en ${GITEA_REPO_PATH}. Saltando push."
        return 0
    fi
    
    cd "$GITEA_REPO_PATH" || return 0
    
    local current_branch=$(git branch --show-current 2>/dev/null || echo "main")
    local repo_owner="${GITEA_REPO_OWNER:-${admin_user}}"
    local repo_url="http://${admin_user}:${admin_password}@${GITEA_HOST}:${GITEA_PORT}/${repo_owner}/${GITEA_REPO_NAME}.git"
    
    # Configurar remote
    if git remote get-url gitea > /dev/null 2>&1; then
        git remote set-url gitea "$repo_url"
    else
        git remote add gitea "$repo_url"
    fi
    
    git config user.name "Gitea Bootstrap" || true
    git config user.email "bootstrap@gitea.local" || true
    
    echo -e "${YELLOW}[Gitea Init]${NC} Haciendo push de la rama '${current_branch}' a Gitea..."
    
    local push_output=$(git push -u gitea "${current_branch}" 2>&1 || true)
    
    if echo "$push_output" | grep -q "Everything up-to-date\|successfully\|To http"; then
        echo -e "${GREEN}[Gitea Init]${NC} ✓ Push exitoso o ya está actualizado!"
    else
        echo -e "${YELLOW}[Gitea Init]${NC} ⚠ Push falló o hay conflictos"
        echo "$push_output" | head -10
    fi
}

# Ejecutar creación de usuario y repositorio
create_jenkins_user "$GITEA_JENKINS_USER" "$GITEA_JENKINS_PASSWORD" "$GITEA_JENKINS_EMAIL" "$GITEA_ADMIN_USER" "$GITEA_ADMIN_PASSWORD" || exit 1

create_repository "$GITEA_REPO_OWNER" "$GITEA_REPO_NAME" "$GITEA_REPO_PRIVATE" "$GITEA_REPO_DESCRIPTION" "$GITEA_ADMIN_USER" "$GITEA_ADMIN_PASSWORD" || exit 1

push_local_repository "$GITEA_ADMIN_USER" "$GITEA_ADMIN_PASSWORD" || echo -e "${YELLOW}[Gitea Init]${NC} ⚠ Push automático falló, pero el repositorio está creado"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✓ INICIALIZACIÓN COMPLETA DE GITEA FINALIZADA                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Resumen:${NC}"
echo -e "   Base de datos: ${GITEA_DB_NAME} (MySQL)"
echo -e "   Usuario admin: ${GITEA_ADMIN_USER}"
echo -e "   Usuario Jenkins: ${GITEA_JENKINS_USER}"
echo -e "   Repositorio: ${GITEA_URL}/${GITEA_REPO_OWNER}/${GITEA_REPO_NAME}"
echo ""

