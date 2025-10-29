FROM php:8.2-fpm

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
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar extensiones de PHP
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configurar directorio de trabajo
WORKDIR /var/www

# Copiar la aplicación Laravel
COPY ./app_backend /var/www

# Copiar el archivo de entorno
COPY ./app_backend/.env.example /var/www/.env

# Instalar/Actualizar dependencias de Composer
RUN composer update --no-dev --optimize-autoloader --no-interaction

# Generar APP_KEY
RUN php artisan key:generate --force

# Publicar configuración de Swagger y generar documentación
RUN php artisan vendor:publish --provider "L5Swagger\L5SwaggerServiceProvider" --force
RUN php artisan l5-swagger:generate

# Configurar permisos
RUN chown -R www-data:www-data /var/www \
    && chmod -R 775 /var/www/storage \
    && chmod -R 775 /var/www/bootstrap/cache

# Copiar entrypoint simplificado
COPY ./backend/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Exponer puerto 9000 para PHP-FPM
EXPOSE 9000

# Configurar entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Comando por defecto
CMD ["php-fpm"]

