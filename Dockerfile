FROM php:8.3-apache

# Cài extension PHP và công cụ cần thiết
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    zip \
    curl \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    nodejs \
    npm \
    && docker-php-ext-install pdo_mysql zip

# Cài Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Bật Apache Rewrite
RUN a2enmod rewrite

WORKDIR /var/www/html

# Copy source
COPY . .

# Cài package PHP
RUN composer install --no-dev --optimize-autoloader

# Cài package Node và build Vite
RUN npm install
RUN npm run build

# Cấp quyền
RUN chown -R www-data:www-data storage bootstrap/cache
RUN chmod -R 775 storage bootstrap/cache

# Apache trỏ vào thư mục public
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf \
    /etc/apache2/apache2.conf \
    /etc/apache2/conf-available/*.conf

EXPOSE 80

CMD php artisan migrate --force && apache2-foreground