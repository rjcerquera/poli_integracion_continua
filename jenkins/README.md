# 🚀 Jenkins CI/CD Configuration

Esta carpeta contiene la configuración personalizada de Jenkins con plugins pre-instalados, configuración automatizada mediante JCasC, y un pipeline de health check completo.

## 📁 Estructura de Archivos

```
jenkins/
├── Dockerfile              # Imagen personalizada de Jenkins
├── plugins.txt             # Lista de plugins a instalar
├── jenkins.yaml            # Configuración as Code (JCasC)
├── Jenkinsfile             # Pipeline de health check y verificación
├── env.example             # Variables de entorno de ejemplo
├── init-scripts/           # Scripts de inicialización Groovy
│   └── createPipeline.groovy  # Script para crear pipeline automáticamente
└── README.md              # Este archivo
```

## 🔧 Archivos Principales

### 1. **Dockerfile**
- Basado en `jenkins/jenkins:lts`
- Instala Docker CLI para DooD (Docker-out-of-Docker)
- Instala plugins automáticamente desde `plugins.txt`
- Configura credenciales parametrizables
- Configura JCasC para configuración automática
- Copia Jenkinsfile y scripts de inicialización
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
- Timezone y timestamps

### 4. **Jenkinsfile**
Pipeline completo de health check que:
- Verifica conectividad de todos los contenedores
- Verifica integración Jenkins-Gitea
- Verifica configuración del plugin de Gitea
- Realiza checkout desde Gitea
- Valida información del último commit
- Muestra estado detallado de la integración

### 5. **init-scripts/createPipeline.groovy**
Script de inicialización que crea automáticamente el pipeline `health-check-pipeline` al iniciar Jenkins.

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

### **Pipeline automático:**
El script `createPipeline.groovy` crea automáticamente el pipeline `health-check-pipeline` al iniciar Jenkins. Puedes ejecutarlo desde la UI de Jenkins.

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
- `generic-webhook-trigger` - Webhooks personalizables

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

### Verificar integración:

El pipeline `health-check-pipeline` verifica automáticamente:
- Plugin de Gitea instalado
- Servidor Gitea configurado
- Webhooks habilitados
- Conectividad con Gitea
- Checkout desde Gitea
- Validación de commits

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

# Ver logs de inicialización
docker logs jenkins_server | grep -i "init\|pipeline"

# Crear pipeline manualmente desde la UI de Jenkins
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
4. ✅ Crear primer Pipeline
5. ✅ Configurar webhooks en Gitea
6. ✅ Verificar integración con el pipeline de health check

## 📝 Notas Importantes

### Comunicación entre Contenedores

- **Dentro de la red Docker**: Usa el **nombre del servicio** (ej: `gitea`, `mysql`)
- **Para docker exec**: Usa el **nombre del contenedor** (ej: `gitea_server`, `jenkins_server`)
- **Ejemplo en Jenkinsfile**:
  - Para conectarse a Gitea: `http://gitea:3000` (nombre del servicio)
  - Para ejecutar comandos: `docker exec gitea_server ...` (nombre del contenedor)

### Pipeline de Health Check

El `Jenkinsfile` incluido realiza verificaciones completas:
- Conectividad de contenedores
- Integración Jenkins-Gitea
- Configuración del plugin de Gitea
- Checkout desde Gitea
- Validación de commits

Este pipeline se crea automáticamente mediante el script `createPipeline.groovy`.
