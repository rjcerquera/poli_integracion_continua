FROM alpine:latest

# Instalar dependencias necesarias
# Incluye: curl, bash, jq, git (para Gitea bootstrap)
#          mysql-client, netcat-openbsd (para inicialización de BD y verificación de red)
#          docker-cli (para ejecutar comandos docker exec en el contenedor de Gitea)
RUN apk add --no-cache \
    curl \
    bash \
    jq \
    git \
    openssh-client \
    mysql-client \
    netcat-openbsd \
    bind-tools \
    docker-cli

# Copiar script de inicialización completa
COPY init-gitea-complete.sh /usr/local/bin/init-gitea-complete.sh
RUN chmod +x /usr/local/bin/init-gitea-complete.sh

# Ejecutar script completo
CMD ["/usr/local/bin/init-gitea-complete.sh"]

