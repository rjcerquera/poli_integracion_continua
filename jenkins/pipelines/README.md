# 📁 Estructura de Pipelines de Jenkins

Este directorio contiene los diferentes pipelines (Jenkinsfiles) organizados por funcionalidad o proyecto.

## 📂 Estructura de Carpetas

```
jenkins/pipelines/
├── README.md                    # Este archivo
├── webhook-pipeline/            # Pipeline para recibir webhooks de Gitea
│   └── Jenkinsfile
├── health-check-pipeline/       # Pipeline de verificación de salud (si se mueve aquí)
│   └── Jenkinsfile
└── [otros-pipelines]/           # Otros pipelines según necesidades
    └── Jenkinsfile
```

## 🔄 Pipelines Disponibles

### 1. Pipeline de Webhook (webhook-pipeline)

Este pipeline se activa automáticamente cuando Gitea envía un webhook después de eventos como:
- Push a una rama
- Pull Request creado/actualizado
- Tags creados
- Otros eventos configurados en Gitea

#### Características

- ✅ Utiliza **Generic Webhook Trigger** para recibir eventos de Gitea
- ✅ Extrae información del webhook (rama, commit, mensaje, etc.)
- ✅ Realiza checkout del código desde Gitea
- ✅ Construye imagen Docker de testing para Laravel
- ✅ Ejecuta pruebas de la aplicación
- ✅ Envía notificaciones por email usando MailHog
- ✅ Soporta Docker-out-of-Docker (DooD) para construir imágenes

#### Configuración

1. **Webhook en Gitea**: El webhook debe apuntar a:
   ```
   http://jenkins:8080/generic-webhook-trigger/invoke?token=gitea-webhook-token
   ```
   (Dentro de la red Docker, usa el nombre del servicio `jenkins`)

2. **Token del Webhook**: El token por defecto es `gitea-webhook-token`. Puedes cambiarlo en el Jenkinsfile.

3. **Pipeline Job en Jenkins**: El job se crea automáticamente mediante el script de inicialización.

#### Variables Extraídas del Webhook

El pipeline extrae automáticamente las siguientes variables del payload de Gitea:
- `ref`: Referencia completa (ej: `refs/heads/main`)
- `branch`: Nombre de la rama (ej: `main`)
- `commit_sha`: Hash del commit
- `commit_message`: Mensaje del commit
- `repo_name`: Nombre del repositorio
- `repo_owner`: Propietario del repositorio
- `pusher_name`: Usuario que hizo el push

### 2. Pipeline de Health Check (health-check-pipeline)

Este pipeline verifica el estado completo del sistema CI/CD y la integración entre servicios.

#### Características

- ✅ Verifica conectividad de todos los contenedores (MySQL, Nginx, Backend, Frontend, Gitea, Jenkins)
- ✅ Verifica integración Jenkins-Gitea
- ✅ Verifica configuración del plugin de Gitea
- ✅ Realiza checkout desde Gitea
- ✅ Valida información del último commit
- ✅ Muestra estado detallado de la integración

#### Uso

Este pipeline puede ejecutarse:
- Manualmente desde la UI de Jenkins
- Programado mediante cron
- Como parte de un pipeline más grande

#### Configuración

El pipeline se crea automáticamente mediante el script de inicialización. No requiere configuración adicional.

## 📋 Buenas Prácticas para Múltiples Pipelines

### 1. **Organización por Funcionalidad**

Cada pipeline debe tener su propia carpeta con:
- `Jenkinsfile` principal
- `README.md` (opcional) con documentación específica
- Scripts auxiliares si es necesario

```
pipelines/
├── backend-pipeline/
│   ├── Jenkinsfile
│   └── scripts/
│       └── deploy.sh
├── frontend-pipeline/
│   └── Jenkinsfile
└── e2e-tests-pipeline/
    └── Jenkinsfile
```

### 2. **Nomenclatura Clara**

- Usar nombres descriptivos: `backend-pipeline`, `frontend-pipeline`, `deploy-pipeline`
- Evitar nombres genéricos como `pipeline1`, `test-pipeline-v2`

### 3. **Compartir Código Común**

Para evitar duplicación, considera:

**Opción A: Biblioteca Compartida de Pipeline**
- Crear una librería de Jenkins con funciones comunes
- Importarla en cada pipeline

**Opción B: Scripts Compartidos**
- Crear carpeta `jenkins/shared-scripts/` con funciones reutilizables
- Incluirlos en cada pipeline según necesidad

**Opción C: Variables Globales**
- Definir variables comunes en `jenkins.yaml` (JCasC)
- Usarlas en todos los pipelines

### 4. **Estructura del Jenkinsfile**

Cada Jenkinsfile debe seguir una estructura clara:

```groovy
pipeline {
    agent any
    
    environment {
        // Variables de entorno compartidas
    }
    
    stages {
        stage('Checkout') { /* ... */ }
        stage('Build') { /* ... */ }
        stage('Test') { /* ... */ }
        stage('Deploy') { /* ... */ }
    }
    
    post {
        success { /* ... */ }
        failure { /* ... */ }
        always { /* ... */ }
    }
}
```

### 5. **Documentación**

Cada pipeline debe incluir:
- Descripción de propósito
- Eventos que lo activan
- Requisitos previos
- Variables de entorno necesarias
- Pasos de configuración

### 6. **Versionado**

- Mantener los Jenkinsfiles en el repositorio Git
- Usar branches para versiones de pipeline
- Documentar cambios importantes

### 7. **Manejo de Credenciales**

- Usar el sistema de credenciales de Jenkins
- Referenciar credenciales por ID en los pipelines
- No hardcodear secretos en los Jenkinsfiles

### 8. **Paralelización**

Cuando sea posible, ejecutar etapas en paralelo:

```groovy
stage('Tests Paralelos') {
    parallel {
        stage('Unit Tests') { /* ... */ }
        stage('Integration Tests') { /* ... */ }
        stage('Lint') { /* ... */ }
    }
}
```

## 🔧 Cómo Agregar un Nuevo Pipeline

1. **Crear carpeta**:
   ```bash
   mkdir -p jenkins/pipelines/mi-nuevo-pipeline
   ```

2. **Crear Jenkinsfile**:
   ```bash
   touch jenkins/pipelines/mi-nuevo-pipeline/Jenkinsfile
   ```

3. **Escribir el pipeline** siguiendo las buenas prácticas

4. **Crear el Job en Jenkins**:
   - Desde la UI: New Item → Pipeline
   - Configurar para usar el Jenkinsfile desde el repositorio Git
   - O usar el script de inicialización para automatizarlo

5. **Configurar triggers** según necesidad (webhook, polling, manual)

6. **Documentar** en el README de la carpeta o en este archivo

## 📝 Ejemplo: Pipeline Mínimo

```groovy
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building...'
                // Comandos de build aquí
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline completed'
        }
    }
}
```

## 🔗 Integración con Gitea

Para que los pipelines se activen automáticamente desde Gitea:

1. **Webhook configurado** en Gitea apuntando a Jenkins
   - URL: `http://jenkins:8080/generic-webhook-trigger/invoke?token=gitea-webhook-token`
   - Eventos: push, pull_request, create, delete
   - El webhook se crea automáticamente mediante `gitea-bootstrap` si `GITEA_CREATE_WEBHOOK=true`

2. **Plugin de Gitea** instalado y configurado en Jenkins
   - Configurado en `jenkins.yaml` con `manageHooks: true`
   - Credenciales configuradas con ID: `gitea-credentials`

3. **Credenciales** configuradas en Jenkins para acceso a Gitea
   - Usuario/contraseña configurados mediante variables de entorno
   - `GITEA_USERNAME` y `GITEA_PASSWORD` en docker-compose.yml

4. **Jobs configurados** automáticamente mediante script de inicialización
   - Los pipelines se crean al iniciar Jenkins por primera vez

## 📧 Notificaciones por Email

Ambos pipelines están configurados para enviar notificaciones por email usando MailHog:

- **Servidor SMTP**: `minio:1025` (dentro de la red Docker)
- **Interfaz web**: http://localhost:8025
- **Configuración**: Definida en `jenkins.yaml` y variables de entorno

Las notificaciones incluyen:
- Estado del build (éxito/fallo)
- Información del commit
- Logs del pipeline
- Tiempo de ejecución

## 📚 Referencias

- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Gitea Plugin for Jenkins](https://plugins.jenkins.io/gitea/)
- [Pipeline Best Practices](https://www.jenkins.io/doc/book/pipeline/pipeline-best-practices/)

