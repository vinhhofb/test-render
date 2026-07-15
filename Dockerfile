FROM php:8.4-apache

# ======================
# Install system packages
# ======================
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    zip \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libicu-dev \
    libpq-dev \
    libsqlite3-dev \
    libsqlite3-0 \
    libssl-dev

# ======================
# Install PHP extensions
# ======================
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    mbstring \
    bcmath \
    exif \
    pcntl \
    intl \
    gd \
    zip

# ======================
# Install Node.js 22
# ======================
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -

RUN apt-get install -y nodejs

# ======================
# Install Composer
# ======================
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# ======================
# Enable Apache Rewrite
# ======================
RUN a2enmod rewrite

WORKDIR /var/www/html

# ======================
# Copy project
# ======================
COPY . .

# ======================
# Install PHP packages
# ======================
RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction

# ======================
# Install JS packages
# ======================
RUN npm install

RUN npm run build

# ======================
# Permissions
# ======================
RUN mkdir -p storage/logs

RUN chown -R www-data:www-data storage bootstrap/cache

RUN chmod -R 775 storage bootstrap/cache

# ======================
# Apache DocumentRoot
# ======================
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf \
    /etc/apache2/apache2.conf \
    /etc/apache2/conf-available/*.conf

EXPOSE 80

CMD ["apache2-foreground"]