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

# Script wrapper que ejecuta la inicialización y luego mantiene el contenedor activo
RUN echo '#!/bin/sh' > /usr/local/bin/entrypoint.sh && \
    echo '/usr/local/bin/init-gitea-complete.sh' >> /usr/local/bin/entrypoint.sh && \
    echo 'echo ""' >> /usr/local/bin/entrypoint.sh && \
    echo 'echo "✅ Inicialización completada. El contenedor permanecerá activo."' >> /usr/local/bin/entrypoint.sh && \
    echo 'echo "💡 Para hacer push manual, ejecuta: docker exec -it gitea_bootstrap sh"' >> /usr/local/bin/entrypoint.sh && \
    echo 'echo ""' >> /usr/local/bin/entrypoint.sh && \
    echo '# Mantener el contenedor activo indefinidamente' >> /usr/local/bin/entrypoint.sh && \
    echo 'exec tail -f /dev/null' >> /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# Ejecutar script wrapper que mantiene el contenedor activo
CMD ["/usr/local/bin/entrypoint.sh"]

