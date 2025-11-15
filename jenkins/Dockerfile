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
    && rm -rf /var/lib/apt/lists/*

# Dar permisos de Docker al usuario jenkins
RUN usermod -aG docker jenkins

# Configurar sudo para que jenkins pueda ejecutar docker sin contraseña
RUN echo "jenkins ALL=(ALL) NOPASSWD: /usr/bin/docker" >> /etc/sudoers.d/jenkins && \
    chmod 0440 /etc/sudoers.d/jenkins

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
    mkdir -p /var/jenkins_home/jenkins-pipeline && \
    chown -R jenkins:jenkins /var/jenkins_home/init.groovy.d && \
    chown -R jenkins:jenkins /var/jenkins_home/jenkins-pipeline

# Cambiar de vuelta a usuario jenkins
USER jenkins

# Copiar Jenkinsfile para que esté disponible en el contenedor
COPY --chown=jenkins:jenkins Jenkinsfile /var/jenkins_home/jenkins-pipeline/Jenkinsfile

# Copiar script de inicialización para crear el pipeline automáticamente
COPY --chown=jenkins:jenkins init-scripts/createPipeline.groovy /var/jenkins_home/init.groovy.d/createPipeline.groovy

# Exponer puertos
EXPOSE 8080 50000

# Healthcheck para verificar que Jenkins está listo
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
  CMD curl -f http://localhost:8080/login || exit 1

# Punto de entrada por defecto de Jenkins
# Se puede sobrescribir con un script personalizado si es necesario

