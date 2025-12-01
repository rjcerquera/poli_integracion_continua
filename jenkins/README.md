# 🚀 Jenkins CI/CD Configuration

Esta carpeta contiene la configuración personalizada de Jenkins con plugins pre-instalados, configuración automatizada mediante JCasC, y pipelines automatizados para CI/CD. Incluye dos pipelines principales: uno para webhooks de Gitea y otro para verificación de salud del sistema.

## 📁 Estructura de Archivos

```
jenkins/
├── Dockerfile              # Imagen personalizada de Jenkins
├── plugins.txt             # Lista de plugins a instalar
├── jenkins.yaml            # Configuración as Code (JCasC)
├── Jenkinsfile             # Pipeline legacy (puede ser removido)
├── env.example             # Variables de entorno de ejemplo
├── init-scripts/           # Scripts de inicialización Groovy
│   └── createPipeline.groovy  # Script para crear pipelines automáticamente
├── pipelines/              # Pipelines organizados por funcionalidad
│   ├── README.md          # Documentación de pipelines
│   ├── webhook-pipeline/  # Pipeline activado por webhooks de Gitea
│   │   └── Jenkinsfile
│   └── health-check-pipeline/  # Pipeline de verificación del sistema
│       └── Jenkinsfile
└── README.md              # Este archivo
```

## 🔧 Archivos Principales

### 1. **Dockerfile**
- Basado en `jenkins/jenkins:lts`
- Instala Docker CLI para DooD (Docker-out-of-Docker)
- Instala Docker Compose Plugin v2 (compatible con Docker 26.1.5+)
- Instala plugins automáticamente desde `plugins.txt`
- Configura credenciales parametrizables
- Configura JCasC para configuración automática
- Copia la carpeta `pipelines/` completa a `/var/jenkins_home/pipelines/`
- Copia scripts de inicialización a `/var/jenkins_home/init.groovy.d/`
- Incluye healthcheck

### 2. **plugins.txt**
Lista de plugins instalados automáticamente:
- **Gitea**: Integración completa con Gitea (webhooks, notificaciones)
- **Git**: Soporte de Git
- **Pipeline**: Pipelines de CI/CD
- **Docker**: Construcción de imágenes Docker
- **JCasC**: Configuración como código
- **Blue Ocean**: UI moderna
- Y más...

### 3. **jenkins.yaml**
Configuración automática de Jenkins usando JCasC:
- Usuario administrador configurable
- Permisos y seguridad
- Credenciales para Gitea (usuario/contraseña)
- Configuración de herramientas (Git)
- Servidor Gitea configurado con webhooks habilitados
- Configuración de SMTP (MailHog) para notificaciones por email
- Timezone y timestamps

### 4. **pipelines/**
Directorio que contiene los pipelines de Jenkins organizados por funcionalidad. Cada pipeline tiene su propia carpeta con su `Jenkinsfile`:

- **webhook-pipeline/**: Pipeline que se activa automáticamente mediante webhooks de Gitea
  - Utiliza Generic Webhook Trigger para recibir eventos de Gitea
  - Construye y prueba la aplicación Laravel
  - Envía notificaciones por email usando MailHog
  - Ubicación: `pipelines/webhook-pipeline/Jenkinsfile`

- **health-check-pipeline/**: Pipeline de verificación de salud del sistema
  - Verifica conectividad de todos los contenedores
  - Verifica integración Jenkins-Gitea
  - Verifica configuración del plugin de Gitea
  - Realiza checkout desde Gitea
  - Valida información del último commit
  - Muestra estado detallado de la integración
  - Ubicación: `pipelines/health-check-pipeline/Jenkinsfile`

Para más detalles sobre los pipelines, consulta [pipelines/README.md](pipelines/README.md).

### 5. **Jenkinsfile** (en la raíz)
Pipeline legacy que puede ser removido. Los pipelines activos están en la carpeta `pipelines/`. Este archivo puede ser una versión anterior del health-check-pipeline.

### 6. **init-scripts/createPipeline.groovy**
Script de inicialización que crea automáticamente los pipelines al iniciar Jenkins. Lee los Jenkinsfiles desde `pipelines/` y crea los jobs correspondientes.

## 🐳 Docker-out-of-Docker (DooD) - Configuración Actual

### ¿Qué es DooD?

**Docker-out-of-Docker (DooD)** es un patrón donde Jenkins, ejecutándose dentro de un contenedor Docker, interactúa directamente con el **Docker daemon del sistema host**, en lugar de usar un Docker daemon interno o contenedores anidados.

### ¿Cómo funciona en esta configuración?

```
┌─────────────────────────────────────────────────────────┐
│  Sistema Host (Docker Engine)                           │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Contenedor Jenkins                                │ │
│  │  ┌─────────────────────────────────────────────┐ │ │
│  │  │  Jenkins ejecuta: docker ps, docker exec     │ │ │
│  │  │  Estos comandos se ejecutan en el HOST      │ │ │
│  │  └─────────────────────────────────────────────┘ │ │
│  │  Socket montado: /var/run/docker.sock            │ │
│  └───────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Otros contenedores (Gitea, MySQL, etc.)          │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Características de la configuración DooD:

1. **Socket Docker montado**: El socket del host (`/var/run/docker.sock`) se monta en el contenedor Jenkins
2. **Docker CLI instalado**: El contenedor tiene `docker.io` instalado para ejecutar comandos Docker
3. **Permisos configurados**: El usuario `jenkins` tiene permisos para usar Docker (grupo `docker` y sudo)
4. **Interacción directa**: Jenkins ejecuta comandos como `docker ps`, `docker exec` que se ejecutan en el **host**, no dentro del contenedor

### ¿Por qué no interactúa con contenedores internos?

- **No hay Docker daemon interno**: El contenedor Jenkins no ejecuta su propio Docker daemon
- **Acceso directo al host**: Todos los comandos Docker se ejecutan en el sistema host
- **Ventaja**: Puede gestionar todos los contenedores del sistema, no solo los suyos
- **Desventaja**: Requiere acceso al socket del host (consideraciones de seguridad)

### Ejemplo en el código:

En el `Jenkinsfile`, cuando se ejecuta:

```groovy
sh "sudo docker ps --format '{{.Names}}' | grep -q '^${container.container}$'"
```

Este comando:
1. Se ejecuta dentro del contenedor Jenkins
2. Usa el Docker CLI instalado en el contenedor
3. Se conecta al Docker daemon del **host** a través del socket montado
4. Lista los contenedores que están corriendo en el **host**
5. Puede ver y gestionar todos los contenedores (Gitea, MySQL, etc.)

### Configuración en docker-compose.yml:

```yaml
jenkins:
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock  # Socket del host
  environment:
    - DOCKER_HOST=unix:///var/run/docker.sock    # Variable de entorno
```

### Ventajas de DooD:

✅ **Simplicidad**: No necesita Docker-in-Docker (DinD)  
✅ **Rendimiento**: No hay overhead de un Docker daemon adicional  
✅ **Acceso completo**: Puede gestionar todos los contenedores del sistema  
✅ **Compatibilidad**: Funciona con cualquier configuración Docker del host  

### Consideraciones de seguridad:

⚠️ **Acceso privilegiado**: El contenedor tiene acceso completo al Docker daemon del host  
⚠️ **Permisos**: El usuario jenkins necesita permisos para usar Docker  
⚠️ **Producción**: En producción, considera usar Docker-in-Docker (DinD) o agentes remotos  

## 🔐 Credenciales Parametrizables

### **Opción 1: Variables de Entorno en docker-compose.yml**

Las credenciales se pueden configurar directamente en el docker-compose.yml:

```yaml
jenkins:
  build:
    context: ./jenkins
    args:
      JENKINS_ADMIN_USER: admin
      JENKINS_ADMIN_PASSWORD: tu_password_seguro
  environment:
    - JENKINS_ADMIN_ID=admin
    - JENKINS_ADMIN_PASSWORD=tu_password_seguro
    - GITEA_USERNAME=jenkins
    - GITEA_PASSWORD=jenkins123
```

### **Opción 2: Archivo .env (Recomendado)**

1. Copiar `env.example` a `.env` en la raíz del proyecto:
   ```bash
   cp env.example .env
   ```
   
   O si prefieres usar el ejemplo de Jenkins:
   ```bash
   cp jenkins/env.example .env
   ```

2. Editar `.env` con tus credenciales:
   ```env
   JENKINS_ADMIN_ID=admin
   JENKINS_ADMIN_PASSWORD=mi_password_super_seguro_123
   GITEA_USERNAME=jenkins
   GITEA_PASSWORD=gitea_password_123
   ```

3. Usar en docker-compose.yml:
   ```yaml
   jenkins:
     build:
       context: ./jenkins
       args:
         JENKINS_ADMIN_USER: ${JENKINS_ADMIN_ID}
         JENKINS_ADMIN_PASSWORD: ${JENKINS_ADMIN_PASSWORD}
     environment:
       - JENKINS_ADMIN_ID=${JENKINS_ADMIN_ID}
       - JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD}
       - GITEA_USERNAME=${GITEA_USERNAME}
       - GITEA_PASSWORD=${GITEA_PASSWORD}
   ```

### **Opción 3: Build-time Arguments**

Pasar credenciales al construir la imagen:

```bash
docker-compose build --build-arg JENKINS_ADMIN_USER=admin \
                      --build-arg JENKINS_ADMIN_PASSWORD=password123 \
                      jenkins
```

## 🚀 Construcción y Despliegue

### **Primera vez - Construir imagen:**
```bash
cd /path/to/project
docker-compose build jenkins
docker-compose up -d jenkins
```

### **Ver logs de instalación:**
```bash
docker logs -f jenkins_server
```

### **Verificar plugins instalados:**
```bash
docker exec jenkins_server jenkins-plugin-cli --list
```

### **Acceder a Jenkins:**
```
URL: http://localhost:8081
Usuario: admin (o el configurado en .env)
Password: admin123 (o el configurado en .env)
```

### **Pipelines automáticos:**
El script `init-scripts/createPipeline.groovy` crea automáticamente los siguientes pipelines al iniciar Jenkins:
- `webhook-pipeline`: Se activa mediante webhooks de Gitea
- `health-check-pipeline`: Verifica el estado del sistema

Los pipelines se leen desde `/var/jenkins_home/pipelines/` y se crean como jobs en Jenkins. Puedes verificar su creación en los logs de Jenkins o desde la UI.

## 🔄 Actualizar Plugins

1. Editar `plugins.txt` y agregar/modificar plugins
2. Reconstruir la imagen:
   ```bash
   docker-compose build jenkins
   docker-compose up -d --force-recreate jenkins
   ```

## 📋 Plugins Incluidos

### **Integración con Gitea**
- `gitea` - Plugin oficial de Gitea (webhooks, notificaciones, GiteaSCMSource)
- `git` - Soporte básico de Git
- `git-client` - Cliente Git avanzado
- `generic-webhook-trigger` - Webhooks personalizables (usado en webhook-pipeline)

### **Pipelines**
- `workflow-aggregator` - Pipeline completo
- `workflow-multibranch` - Multi-branch pipelines
- `pipeline-stage-view` - Visualización de stages
- `pipeline-graph-view` - Gráficos de pipeline

### **Docker**
- `docker-workflow` - Pipeline con Docker
- `docker-plugin` - Integración Docker
- `docker-commons` - Utilidades comunes de Docker

### **Configuración**
- `configuration-as-code` - JCasC (Configuración como código)
- `job-dsl` - Crear jobs programáticamente

### **Notificaciones**
- `mailer` - Envío de emails (configurado con MailHog)

### **UI**
- `blueocean` - Interfaz moderna

## 🔒 Seguridad

### **Credenciales por Defecto**
```
Usuario: admin
Password: admin123
```

⚠️ **IMPORTANTE**: Cambiar estas credenciales en producción

### **Cambiar Credenciales**

**Método 1 - Antes de construir:**
Editar `.env` antes de ejecutar `docker-compose build`

**Método 2 - Después de desplegar:**
1. Acceder a Jenkins UI
2. Ir a: Manage Jenkins → Security → Configure Global Security
3. Cambiar password del usuario admin

**Método 3 - Desde la consola:**
```bash
docker exec -it jenkins_server bash
# Dentro del contenedor:
# Cambiar password usando jenkins-cli o scripts groovy
```

## 🔌 Integración con Gitea

### Configuración del Plugin

El plugin de Gitea está configurado en `jenkins.yaml`:

```yaml
giteaServers:
  servers:
    - displayName: "Gitea Server"
      serverUrl: "http://gitea:3000"  # Nombre del servicio en docker-compose
      manageHooks: true                # Webhooks automáticos habilitados
      credentialsId: "gitea-credentials"
```

### Características habilitadas:

✅ **Webhooks automáticos**: Jenkins gestiona webhooks en Gitea automáticamente  
✅ **Notificaciones**: Los builds se notifican a Gitea  
✅ **Validación de credenciales**: Las credenciales se validan contra el servidor Gitea  
✅ **Checkout**: El pipeline puede hacer checkout desde Gitea  

### Pipelines Disponibles

El proyecto incluye dos pipelines principales:

1. **webhook-pipeline**: Se activa automáticamente cuando Gitea envía un webhook
   - Utiliza Generic Webhook Trigger para recibir eventos
   - Construye y prueba la aplicación Laravel
   - Envía notificaciones por email
   - URL del webhook: `http://jenkins:8080/generic-webhook-trigger/invoke?token=gitea-webhook-token`

2. **health-check-pipeline**: Pipeline de verificación de salud del sistema
   - Verifica conectividad de todos los contenedores
   - Verifica integración Jenkins-Gitea
   - Verifica configuración del plugin de Gitea
   - Realiza checkout desde Gitea
   - Valida información del último commit

Para más detalles sobre los pipelines, consulta [pipelines/README.md](pipelines/README.md).

## 📧 Configuración de SMTP (MailHog)

Jenkins está configurado para enviar notificaciones por email usando MailHog, un servidor SMTP de desarrollo que captura todos los emails enviados.

### Configuración en jenkins.yaml

```yaml
mailer:
  charset: "UTF-8"
  smtpHost: "minio"        # Nombre del servicio MailHog en docker-compose
  smtpPort: "1025"         # Puerto SMTP de MailHog
  useSsl: false
  useTls: false
  defaultSuffix: "@localhost"
  replyToAddress: "jenkins@localhost"
```

### Acceder a MailHog

- **Interfaz web**: http://localhost:8025
- **Servidor SMTP**: `minio:1025` (dentro de la red Docker) o `localhost:1025` (desde el host)

### Variables de Entorno

Las siguientes variables se pueden configurar en `docker-compose.yml` o `.env`:

```env
SMTP_HOST=minio              # Nombre del servicio MailHog
SMTP_PORT=1025               # Puerto SMTP
SMTP_FROM=jenkins@localhost  # Dirección de remitente
SMTP_TO=admin@example.com    # Dirección de destinatario
```

### Verificar Emails Enviados

1. Accede a la interfaz web de MailHog: http://localhost:8025
2. Todos los emails enviados por Jenkins aparecerán en la interfaz
3. Puedes ver el contenido completo, headers y destinatarios

### Notas Importantes

- MailHog no requiere autenticación (ideal para desarrollo)
- Los emails no se envían realmente, solo se capturan para pruebas
- En producción, configura un servidor SMTP real

## 🐛 Troubleshooting

### **Jenkins no inicia:**
```bash
# Ver logs
docker logs jenkins_server

# Ver si hay errores de permisos
docker exec jenkins_server ls -la /var/jenkins_home
```

### **Plugins no se instalan:**
```bash
# Verificar que plugins.txt está correcto
cat jenkins/plugins.txt

# Reconstruir sin caché
docker-compose build --no-cache jenkins
```

### **No puedo acceder a Jenkins:**
```bash
# Verificar que el contenedor está corriendo
docker ps | grep jenkins

# Verificar puerto
curl http://localhost:8081
```

### **Problemas con Docker (DooD):**
```bash
# Verificar que el socket está montado
docker exec jenkins_server ls -la /var/run/docker.sock

# Verificar permisos
docker exec jenkins_server docker ps

# Verificar que el usuario jenkins puede usar docker
docker exec jenkins_server sudo docker ps

# Verificar grupo docker
docker exec jenkins_server groups jenkins
```

### **Problemas con Gitea:**
```bash
# Verificar que el plugin está instalado
docker exec jenkins_server ls /var/jenkins_home/plugins/ | grep gitea

# Verificar conectividad desde Jenkins a Gitea
docker exec jenkins_server curl http://gitea:3000/api/v1/version

# Verificar configuración del plugin
docker exec jenkins_server cat /var/jenkins_home/casc_configs/jenkins.yaml
```

### **Pipeline no se crea automáticamente:**
```bash
# Verificar que el script de inicialización existe
docker exec jenkins_server ls /var/jenkins_home/init.groovy.d/

# Verificar que los pipelines están copiados
docker exec jenkins_server ls -la /var/jenkins_home/pipelines/

# Ver logs de inicialización
docker logs jenkins_server | grep -i "init\|pipeline"

# Crear pipeline manualmente desde la UI de Jenkins
```

### **Pipelines no encontrados:**
```bash
# Verificar que los pipelines están en el contenedor
docker exec jenkins_server ls -la /var/jenkins_home/pipelines/

# Verificar estructura de pipelines
docker exec jenkins_server find /var/jenkins_home/pipelines -name "Jenkinsfile"

# Verificar contenido de un pipeline
docker exec jenkins_server cat /var/jenkins_home/pipelines/health-check-pipeline/Jenkinsfile | head -20
```

### **Problemas con MailHog/SMTP:**
```bash
# Verificar que MailHog está corriendo
docker ps | grep mailhog

# Verificar conectividad desde Jenkins a MailHog
docker exec jenkins_server curl http://minio:8025

# Verificar configuración SMTP en jenkins.yaml
docker exec jenkins_server cat /var/jenkins_home/casc_configs/jenkins.yaml | grep -A 10 mailer
```

### **Problemas con Docker Compose:**
```bash
# Verificar que Docker Compose v2 está instalado
docker exec jenkins_server docker compose version

# Verificar que el plugin está en el directorio correcto
docker exec jenkins_server ls -la /usr/local/lib/docker/cli-plugins/
```

## 📚 Documentación Adicional

- [Jenkins Official Docs](https://www.jenkins.io/doc/)
- [Gitea Plugin](https://plugins.jenkins.io/gitea/)
- [JCasC Documentation](https://github.com/jenkinsci/configuration-as-code-plugin)
- [Docker Workflow Plugin](https://plugins.jenkins.io/docker-workflow/)
- [Docker-out-of-Docker Pattern](https://www.jenkins.io/doc/book/using/using-agents/#docker-outside-of-docker)

## 🎯 Próximos Pasos

1. ✅ Construir imagen de Jenkins
2. ✅ Verificar acceso a Jenkins UI
3. ✅ Configurar conexión con Gitea
4. ✅ Crear pipelines (webhook-pipeline y health-check-pipeline)
5. ✅ Configurar webhooks en Gitea
6. ✅ Verificar integración con los pipelines
7. ✅ Configurar notificaciones por email (MailHog)

## 📝 Notas Importantes

### Comunicación entre Contenedores

- **Dentro de la red Docker**: Usa el **nombre del servicio** (ej: `gitea`, `mysql`)
- **Para docker exec**: Usa el **nombre del contenedor** (ej: `gitea_server`, `jenkins_server`)
- **Ejemplo en Jenkinsfile**:
  - Para conectarse a Gitea: `http://gitea:3000` (nombre del servicio)
  - Para ejecutar comandos: `docker exec gitea_server ...` (nombre del contenedor)

### Pipelines Disponibles

El proyecto incluye dos pipelines principales que se crean automáticamente:

1. **webhook-pipeline** (`pipelines/webhook-pipeline/Jenkinsfile`): Se activa mediante webhooks de Gitea
   - Construye y prueba la aplicación Laravel
   - Envía notificaciones por email
   - Utiliza Generic Webhook Trigger
   - URL del webhook: `http://jenkins:8080/generic-webhook-trigger/invoke?token=gitea-webhook-token`

2. **health-check-pipeline** (`pipelines/health-check-pipeline/Jenkinsfile`): Verifica el estado del sistema
   - Conectividad de contenedores
   - Integración Jenkins-Gitea
   - Configuración del plugin de Gitea
   - Checkout desde Gitea
   - Validación de commits

Ambos pipelines se crean automáticamente mediante el script `init-scripts/createPipeline.groovy`, que:
- Lee los Jenkinsfiles desde `/var/jenkins_home/pipelines/`
- Crea los jobs correspondientes en Jenkins
- Configura los triggers y parámetros necesarios

**Nota**: El `Jenkinsfile` en la raíz de `jenkins/` es legacy y puede ser removido. Los pipelines activos están en `pipelines/`.

Para más detalles sobre los pipelines, consulta [pipelines/README.md](pipelines/README.md).
