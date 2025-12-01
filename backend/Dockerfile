# Build argument para seleccionar imagen base (php:8.2-fpm para producción, php:8.2-cli para testing)
ARG PHP_IMAGE=php:8.2-fpm

FROM ${PHP_IMAGE}

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    sqlite3 \
    libsqlite3-dev \
    $PHPIZE_DEPS \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar extensiones de PHP
RUN docker-php-ext-install pdo_mysql pdo_sqlite mbstring exif pcntl bcmath gd zip

# Instalar PCOV para cobertura de código (más rápido que Xdebug)
RUN pecl install pcov && docker-php-ext-enable pcov

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configurar directorio de trabajo
WORKDIR /var/www

# Copiar la aplicación Laravel
COPY ./app_backend /var/www

# Copiar el archivo de entorno
COPY ./app_backend/.env.example /var/www/.env

# Instalar/Actualizar dependencias de Composer (incluyendo dev para pruebas)
# Usar update para regenerar lock file si está desactualizado (resuelve el error de composer.lock)
RUN composer update --optimize-autoloader --no-interaction

# Generar APP_KEY
RUN php artisan key:generate --force || true

# Configurar permisos
RUN chown -R www-data:www-data /var/www \
    && chmod -R 775 /var/www/storage \
    && chmod -R 775 /var/www/bootstrap/cache

# Configurar PCOV para cobertura de código
ENV PCOV_ENABLED=1
ENV PCOV_EXCLUDE='vendor,storage,node_modules'

# Variables de entorno configurables mediante build args
# Los valores se pasan desde docker-compose (build.args) o desde el comando docker build
# Para testing: usar APP_ENV=testing, DB_CONNECTION=sqlite, DB_DATABASE=:memory:
# NOTA: Si no se pasan build args, estos valores estarán vacíos y las variables de entorno
#       del runtime (desde docker-compose environment:) las establecerán/sobrescribirán
ARG APP_ENV
ARG DB_CONNECTION
ARG DB_DATABASE

# Convertir build args a variables de entorno (disponibles en runtime)
# Si los ARG no se pasan, quedarán vacíos y las variables de entorno del runtime las sobrescribirán
ENV APP_ENV=${APP_ENV}
ENV DB_CONNECTION=${DB_CONNECTION}
ENV DB_DATABASE=${DB_DATABASE}

# Publicar configuración de Swagger solo si no es testing (evita errores en testing)
# Verificar si APP_ENV está definido y no es "testing"
RUN if [ -z "${APP_ENV}" ] || [ "${APP_ENV}" != "testing" ]; then \
        php artisan vendor:publish --provider "L5Swagger\L5SwaggerServiceProvider" --force || true; \
        php artisan l5-swagger:generate || true; \
    fi

# Copiar entrypoint (para producción)
# NOTA: COPY no admite sintaxis condicional de shell. Si el archivo no existe,
#       el build fallará. Como el archivo existe, lo copiamos directamente.
COPY ./backend/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Exponer puerto 9000 para PHP-FPM (en testing no se usa, pero no causa problemas)
EXPOSE 9000

# Configurar comando por defecto (para producción)
# Para testing, el comando se sobrescribe en docker run con: ./vendor/bin/phpunit --coverage-text
ENTRYPOINT []
CMD ["php-fpm"]
