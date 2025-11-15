# 🚀 Gitea Bootstrap - Auto-Initialization

Este directorio contiene scripts y configuración para **inicializar automáticamente Gitea** cuando se inicia el contenedor. El script realiza una inicialización completa que incluye la creación de la base de datos MySQL, usuarios y repositorios.

## 📁 Archivos

- `init-gitea-complete.sh` - Script completo que inicializa MySQL, crea usuarios y repositorios
- `Dockerfile` - Imagen Alpine con herramientas necesarias (curl, bash, jq, git, mysql-client, docker-cli)
- `README.md` - Este archivo

## ⚙️ Configuración

### Variables de Entorno Requeridas

Edita tu archivo `.env` (o `env.example`) con las siguientes variables:

```env
# ============================================
# CONFIGURACIÓN DE MYSQL
# ============================================
MYSQL_HOST=mysql                    # Nombre del servicio MySQL en docker-compose
MYSQL_PORT=3306
MYSQL_ROOT_PASSWORD=root_password    # Contraseña root de MySQL
GITEA_DB_NAME=gitea                 # Nombre de la base de datos para Gitea
GITEA_DB_USER=gitea_user            # Usuario de la base de datos
GITEA_DB_PASSWORD=gitea_password    # Contraseña del usuario de BD

# ============================================
# CONFIGURACIÓN DE GITEA
# ============================================
# NOTA: GITEA_HOST debe ser el nombre del SERVICIO en docker-compose (no el nombre del contenedor)
#       Dentro de la red Docker, los servicios se comunican usando el nombre del servicio
GITEA_HOST=gitea                    # Nombre del servicio Gitea en docker-compose
GITEA_PORT=3000
GITEA_CONTAINER_NAME=gitea_server   # Nombre del contenedor (para docker exec)
GITEA_ADMIN_USER=admin              # Usuario administrador de Gitea
GITEA_ADMIN_PASSWORD=admin123        # Contraseña del usuario admin
GITEA_ADMIN_EMAIL=admin@example.com # Email del usuario admin

# ============================================
# CONFIGURACIÓN DEL REPOSITORIO
# ============================================
GITEA_REPO_OWNER=admin              # Propietario del repositorio (vacío = usa admin)
GITEA_REPO_NAME=poli_integracion_continua
GITEA_REPO_PRIVATE=true             # true = privado, false = público
GITEA_REPO_DESCRIPTION=Proyecto de Integración Continua

# ============================================
# CONFIGURACIÓN DEL USUARIO JENKINS
# ============================================
GITEA_JENKINS_USER=jenkins          # Usuario Jenkins en Gitea
GITEA_JENKINS_PASSWORD=jenkins123   # Contraseña del usuario Jenkins
GITEA_JENKINS_EMAIL=jenkins@example.com

# ============================================
# PUSH AUTOMÁTICO (OPCIONAL)
# ============================================
GITEA_AUTO_PUSH=true                # true = hace push automático, false = solo crea repo
GITEA_REPO_PATH=/workspace          # Ruta del repositorio local a hacer push
```

### Variables Importantes

- **`GITEA_HOST`**: Debe ser el **nombre del servicio** en `docker-compose.yml` (por defecto: `gitea`), no el nombre del contenedor
- **`GITEA_CONTAINER_NAME`**: Nombre del contenedor Docker (por defecto: `gitea_server`), usado para `docker exec`
- **`GITEA_ADMIN_USER`** y **`GITEA_ADMIN_PASSWORD`**: Credenciales del usuario administrador que se crearán en Gitea
- **`GITEA_AUTO_PUSH`**: Si está en `true`, el script intentará hacer push del código local al repositorio creado

## 🚀 Uso

### Primera vez - Construir e iniciar:

```bash
cd /path/to/project

# Construir la imagen de inicialización
docker-compose build gitea-bootstrap

# Iniciar todos los servicios (incluyendo gitea-bootstrap)
docker-compose up -d
```

### Ver logs de inicialización:

```bash
docker logs gitea_bootstrap
```

### Ejecutar manualmente (si falló):

```bash
docker-compose up gitea-bootstrap
```

## 📋 Qué hace el script

El script `init-gitea-complete.sh` realiza los siguientes pasos en orden:

### Paso 1: Inicialización de Base de Datos MySQL
1. ✅ Espera a que MySQL esté disponible (hasta 60 intentos)
2. ✅ Crea la base de datos `gitea` si no existe
3. ✅ Crea el usuario de base de datos `gitea_user` si no existe
4. ✅ Otorga permisos al usuario sobre la base de datos
5. ✅ Verifica que la base de datos fue creada correctamente

### Paso 2: Esperar a que Gitea esté disponible
1. ✅ Espera a que Gitea responda en la URL configurada (hasta 60 intentos)
2. ✅ Verifica que la API de Gitea esté disponible (`/api/v1/version`)
3. ✅ Muestra información de debug si hay problemas de conectividad

### Paso 3: Crear Usuario Administrador
1. ✅ Verifica si el usuario admin ya existe y las credenciales son válidas
2. ✅ Si no existe, intenta crear el usuario usando **CLI de Gitea**:
   - Usa `docker exec` para ejecutar `gitea admin user create` dentro del contenedor
   - Ejecuta como usuario `git` (Gitea no puede ejecutarse como root)
3. ✅ Si falla CLI, intenta crear usando **API REST** como fallback
4. ✅ Verifica que el usuario fue creado correctamente (hasta 15 intentos)

### Paso 4: Configurar Usuarios y Repositorios
1. ✅ Crea el usuario **Jenkins** en Gitea (si no existe)
2. ✅ Crea el repositorio configurado (si no existe)
3. ✅ Configura la visibilidad del repositorio (público/privado)
4. ✅ **OPCIONAL**: Hace push automático del código local (si `GITEA_AUTO_PUSH=true`)

## 🔍 Verificar que funcionó

```bash
# Ver logs
docker logs gitea_bootstrap

# Deberías ver algo como:
# [MySQL Init] ✓ Base de datos 'gitea' creada exitosamente
# [Gitea Init] ✓ Usuario admin creado exitosamente usando CLI
# [Gitea Init] ✓ Usuario Jenkins creado exitosamente!
# [Gitea Init] ✓ Repositorio creado exitosamente!
# [Gitea Init] URL: http://gitea:3000/admin/poli_integracion_continua
# [Gitea Init] ✓ Push exitoso o ya está actualizado! (si GITEA_AUTO_PUSH=true)
```

Luego accede a Gitea en `http://localhost:3001` (o la URL configurada) y verifica que:
- ✅ El repositorio existe
- ✅ El usuario admin existe (puedes iniciar sesión con las credenciales configuradas)
- ✅ El usuario Jenkins existe
- ✅ El código está subido (si habilitaste push automático)

## 🔧 Troubleshooting

### Error: "MySQL no está disponible"
- Espera más tiempo (MySQL puede tardar en iniciar)
- Verifica que el contenedor de MySQL esté corriendo: `docker ps | grep mysql`
- Verifica que `MYSQL_HOST` sea el nombre del **servicio** en docker-compose, no el nombre del contenedor
- Verifica las credenciales de MySQL (`MYSQL_ROOT_PASSWORD`)

### Error: "Gitea no está disponible"
- Espera más tiempo (Gitea tarda ~1-2 minutos en iniciar)
- Verifica que el contenedor de Gitea esté corriendo: `docker ps | grep gitea`
- Verifica que `GITEA_HOST` sea el nombre del **servicio** en docker-compose (por defecto: `gitea`)
- **IMPORTANTE**: Dentro de la red Docker, usa el nombre del servicio, no `localhost` ni el nombre del contenedor

### Error: "No se pudo crear el usuario admin"
- Verifica que `GITEA_CONTAINER_NAME` sea correcto (nombre del contenedor, no del servicio)
- Verifica que el contenedor tenga acceso al socket de Docker (`/var/run/docker.sock` montado)
- Verifica que `docker-cli` esté instalado en el contenedor bootstrap
- El script intenta CLI primero, luego API como fallback
- Puedes verificar manualmente: `docker exec gitea_server su git -c 'gitea admin user list'`

### Error: "El repositorio ya existe"
- Esto es normal si ya ejecutaste el script antes
- El script es idempotente: puedes ejecutarlo múltiples veces sin problemas
- Si necesitas recrear el repositorio, elimínalo primero desde la UI de Gitea

### El contenedor gitea-bootstrap se ejecuta cada vez
- Esto es normal, pero solo crea recursos si no existen
- El contenedor tiene `restart: "no"` en docker-compose, por lo que solo se ejecuta una vez
- Puedes eliminarlo después: `docker-compose rm gitea-bootstrap`

### Push automático falló
- Verifica que `GITEA_AUTO_PUSH=true` en tu `.env`
- Verifica que el directorio montado (`/workspace`) sea un repositorio git válido
- Verifica que las credenciales del admin sean correctas
- El push puede fallar si el repositorio ya tiene contenido - esto es normal
- Puedes hacer push manualmente después: `git push gitea main`
- El script agrega un remote `gitea` a tu repositorio local

### Error: "docker exec: command not found"
- Verifica que `docker-cli` esté instalado en el Dockerfile del contenedor bootstrap
- Verifica que `/var/run/docker.sock` esté montado en el contenedor bootstrap en `docker-compose.yml`

## 🐳 Docker-out-of-Docker (DooD) - Configuración Actual

### ¿Qué es DooD?

**Docker-out-of-Docker (DooD)** es un patrón donde el contenedor `gitea-bootstrap`, ejecutándose dentro de Docker, interactúa directamente con el **Docker daemon del sistema host**, en lugar de usar un Docker daemon interno o contenedores anidados.

### ¿Cómo funciona en esta configuración?

```
┌─────────────────────────────────────────────────────────┐
│  Sistema Host (Docker Engine)                           │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Contenedor gitea-bootstrap                       │ │
│  │  ┌─────────────────────────────────────────────┐ │ │
│  │  │  Script ejecuta: docker exec gitea_server    │ │ │
│  │  │  Este comando se ejecuta en el HOST          │ │ │
│  │  └─────────────────────────────────────────────┘ │ │
│  │  Socket montado: /var/run/docker.sock            │ │
│  └───────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Contenedor Gitea (gitea_server)                  │ │
│  │  El script ejecuta comandos CLI dentro de este   │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Características de la configuración DooD:

1. **Socket Docker montado**: El socket del host (`/var/run/docker.sock`) se monta en el contenedor `gitea-bootstrap`
2. **Docker CLI instalado**: El contenedor tiene `docker-cli` instalado para ejecutar comandos Docker
3. **Interacción directa**: El script ejecuta comandos como `docker exec gitea_server ...` que se ejecutan en el **host**, no dentro del contenedor bootstrap
4. **Ejecución en contenedor remoto**: Los comandos se ejecutan dentro del contenedor de Gitea, pero el control viene del host

### ¿Por qué no interactúa con contenedores internos?

- **No hay Docker daemon interno**: El contenedor `gitea-bootstrap` no ejecuta su propio Docker daemon
- **Acceso directo al host**: Todos los comandos Docker se ejecutan en el sistema host
- **Ventaja**: Puede gestionar y ejecutar comandos en cualquier contenedor del sistema (Gitea, MySQL, etc.)
- **Desventaja**: Requiere acceso al socket del host (consideraciones de seguridad)

### Ejemplo en el código:

En el script `init-gitea-complete.sh`, cuando se ejecuta:

```bash
docker exec gitea_server su git -c "gitea admin user create ..."
```

Este comando:
1. Se ejecuta dentro del contenedor `gitea-bootstrap`
2. Usa el Docker CLI instalado en el contenedor bootstrap
3. Se conecta al Docker daemon del **host** a través del socket montado
4. Ejecuta el comando dentro del contenedor `gitea_server` (que está corriendo en el host)
5. El comando se ejecuta como usuario `git` dentro del contenedor de Gitea

### Configuración en docker-compose.yml:

```yaml
gitea-bootstrap:
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock  # Socket del host
  # ...
```

Y en el Dockerfile:

```dockerfile
RUN apk add --no-cache \
    docker-cli  # Cliente Docker para ejecutar comandos
```

### Ventajas de DooD en este contexto:

✅ **Simplicidad**: No necesita Docker-in-Docker (DinD)  
✅ **Rendimiento**: No hay overhead de un Docker daemon adicional  
✅ **Acceso completo**: Puede ejecutar comandos en cualquier contenedor del sistema  
✅ **Compatibilidad**: Funciona con cualquier configuración Docker del host  
✅ **Necesario para CLI de Gitea**: Permite ejecutar comandos CLI de Gitea dentro de su contenedor sin necesidad de acceso directo  

### Consideraciones de seguridad:

⚠️ **Acceso privilegiado**: El contenedor tiene acceso completo al Docker daemon del host  
⚠️ **Permisos**: El contenedor necesita acceso al socket de Docker  
⚠️ **Producción**: En producción, considera usar Docker-in-Docker (DinD) o métodos alternativos  

### ¿Por qué es necesario en este caso?

El script necesita ejecutar comandos CLI de Gitea (`gitea admin user create`) dentro del contenedor de Gitea. Para hacer esto:

1. **Opción 1 (usada)**: Usar `docker exec` desde el contenedor bootstrap → Requiere DooD
2. **Opción 2**: Acceder directamente al contenedor → No es posible desde otro contenedor sin DooD
3. **Opción 3**: Usar solo API REST → Funciona pero CLI es más confiable para creación de usuarios

El patrón DooD permite que el contenedor bootstrap ejecute comandos en el contenedor de Gitea de forma segura y eficiente.

## 📝 Notas Importantes

### Comunicación entre Contenedores

- **Dentro de la red Docker**: Usa el **nombre del servicio** (ej: `gitea`, `mysql`)
- **Para docker exec**: Usa el **nombre del contenedor** (ej: `gitea_server`, `laravel_mysql`)
- **Ejemplo**: 
  - Para conectarse a Gitea desde otro contenedor: `http://gitea:3000` (nombre del servicio)
  - Para ejecutar comandos en Gitea: `docker exec gitea_server ...` (nombre del contenedor)

### Creación del Usuario Admin

El script crea el usuario admin usando el **CLI de Gitea** dentro del contenedor:
- Usa `docker exec` para ejecutar comandos en el contenedor de Gitea
- Ejecuta como usuario `git` (Gitea no puede ejecutarse como root)
- Comando: `docker exec gitea_server su git -c "gitea admin user create ..."`
- Si falla, intenta usar la API REST como fallback

### Idempotencia

- El script es **idempotente**: puedes ejecutarlo múltiples veces sin problemas
- Solo crea recursos si no existen
- Si un recurso ya existe, el script continúa sin errores

### Push Automático

- El push automático usa las credenciales del usuario admin
- Agrega un remote `gitea` a tu repositorio local
- Hace push de la rama actual a Gitea
- Si falla, el repositorio sigue creado y puedes hacer push manualmente

## 🚀 Push Automático

Para habilitar el push automático del código local:

1. Asegúrate de tener las credenciales del admin configuradas en tu `.env`:
   ```env
   GITEA_ADMIN_USER=admin
   GITEA_ADMIN_PASSWORD=admin123
   ```

2. Edita tu `.env`:
   ```env
   GITEA_AUTO_PUSH=true
   ```

3. Asegúrate de que el directorio `/workspace` esté montado y sea un repositorio git válido

4. Reconstruir y ejecutar:
   ```bash
   docker-compose build gitea-bootstrap
   docker-compose up gitea-bootstrap
   ```

**Nota:** El push automático usa las credenciales del usuario admin (`GITEA_ADMIN_USER` y `GITEA_ADMIN_PASSWORD`) para autenticación. No se requieren tokens adicionales.

El script:
- Agregará el remote `gitea` a tu repositorio local
- Hará push de la rama actual a Gitea
- Si falla, puedes hacer push manualmente después

## 🔐 Seguridad

- Las contraseñas se pasan como variables de entorno
- El script no muestra contraseñas en los logs (solo muestra `<hidden>`)
- Las credenciales se usan para autenticación HTTP básica en las llamadas a la API
- Para producción, considera usar secrets de Docker o un gestor de secretos

## 📚 Referencias

- [Documentación de Gitea](https://docs.gitea.io/)
- [Gitea API Documentation](https://docs.gitea.io/api-usage/)
- [Gitea CLI Commands](https://docs.gitea.io/administration/command-line/)
