FROM jenkins/jenkins:lts

# Información del mantenedor
LABEL maintainer="CI/CD Team"
LABEL description="Jenkins with Gitea integration and Docker support"

# Cambiar a usuario root para instalaciones del sistema
USER root

# ============================================
# INSTALAR DEPENDENCIAS DEL SISTEMA
# ============================================
RUN apt-get update && \
    apt-get install -y \
    docker.io \
    git \
    curl \
    vim \
    sudo \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Instalar Docker Compose Plugin v2 - compatible con Docker 26.1.5+
# NOTA: Docker Compose v2 se integra con Docker CLI como plugin: docker compose
# ESTRATEGIA: Instalar el binario directamente desde GitHub (método más compatible)
RUN set -eux && \
    echo "📦 Instalando Docker Compose Plugin (v2)..." && \
    # Detectar arquitectura
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        COMPOSE_ARCH="x86_64"; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        COMPOSE_ARCH="aarch64"; \
    elif [ "$ARCH" = "armv7l" ] || [ "$ARCH" = "armhf" ]; then \
        COMPOSE_ARCH="armv7"; \
    else \
        COMPOSE_ARCH="x86_64"; \
    fi && \
    echo "   Arquitectura detectada: ${COMPOSE_ARCH}" && \
    # Crear directorio para plugins de Docker
    mkdir -p /usr/local/lib/docker/cli-plugins && \
    # Descargar Docker Compose v2 desde GitHub (versión estable)
    COMPOSE_VERSION="v2.24.5" && \
    echo "   Descargando Docker Compose ${COMPOSE_VERSION}..." && \
    curl -L --fail --show-error --retry 3 \
        "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${COMPOSE_ARCH}" \
        -o /usr/local/lib/docker/cli-plugins/docker-compose && \
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose && \
    # Verificar instalación
    echo "   Verificando instalación..." && \
    docker compose version && \
    echo "✅ Docker Compose Plugin (v2) instalado correctamente"

# Dar permisos de Docker al usuario jenkins
RUN usermod -aG docker jenkins

# Configurar sudo para que jenkins pueda ejecutar comandos sin contraseña
# Esto es necesario para Docker-out-of-Docker cuando el socket requiere permisos root
RUN echo "jenkins ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/jenkins && \
    chmod 0440 /etc/sudoers.d/jenkins && \
    # Verificar que el archivo se creó correctamente
    test -f /etc/sudoers.d/jenkins && \
    # Asegurar que los permisos son correctos
    chown root:root /etc/sudoers.d/jenkins

# ============================================
# CONFIGURACIÓN DE JENKINS
# ============================================

# Cambiar a usuario jenkins para instalar plugins
USER jenkins

# Copiar lista de plugins
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt

# Instalar plugins automáticamente
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# ============================================
# VARIABLES DE ENTORNO PARA JENKINS
# ============================================

# Saltar el wizard de configuración inicial
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Configuración de timezone (opcional)
ENV TZ=America/Bogota

# ============================================
# CREDENCIALES POR DEFECTO (Se pueden sobrescribir)
# ============================================
# Estas se pueden parametrizar desde docker-compose.yml
# o usando variables de entorno al ejecutar el contenedor

ARG JENKINS_ADMIN_USER=admin
ARG JENKINS_ADMIN_PASSWORD=admin123

ENV JENKINS_ADMIN_ID=${JENKINS_ADMIN_USER}
ENV JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD}

# ============================================
# CONFIGURACIÓN INICIAL CON JCasC
# ============================================
# Copiar archivo de configuración Jenkins as Code
COPY --chown=jenkins:jenkins jenkins.yaml /var/jenkins_home/casc_configs/jenkins.yaml

# Configurar JCasC para que use el archivo
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs/jenkins.yaml

# ============================================
# COPIAR JENKINSFILE Y SCRIPTS DE INICIALIZACIÓN
# ============================================
# Cambiar a root temporalmente para crear directorios
USER root

# Crear directorios con permisos correctos
RUN mkdir -p /var/jenkins_home/init.groovy.d && \
    mkdir -p /var/jenkins_home/pipelines && \
    chown -R jenkins:jenkins /var/jenkins_home/init.groovy.d && \
    chown -R jenkins:jenkins /var/jenkins_home/pipelines

# Copiar todas las carpetas de pipelines (como root para tener permisos)
COPY --chown=jenkins:jenkins pipelines/ /var/jenkins_home/pipelines/

# Copiar script de inicialización para crear los pipelines automáticamente
COPY --chown=jenkins:jenkins init-scripts/createPipeline.groovy /var/jenkins_home/init.groovy.d/createPipeline.groovy

# Cambiar de vuelta a usuario jenkins
USER jenkins

# Exponer puertos
EXPOSE 8080 50000

# Healthcheck para verificar que Jenkins está listo
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
  CMD curl -f http://localhost:8080/login || exit 1

# Punto de entrada por defecto de Jenkins
# Se puede sobrescribir con un script personalizado si es necesario

