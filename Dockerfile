# Use official PHP 8.1 Apache image as base
FROM php:8.1-apache

# Set environment variables
ENV MOODLE_VERSION=4.3.5
ENV MOODLE_URL=https://download.moodle.org/stable403/moodle-${MOODLE_VERSION}.tgz
ENV APACHE_DOCUMENT_ROOT=/var/www/html

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libonig-dev \
    libssl-dev \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    mbstring \
    mysqli \
    pdo_mysql \
    xmlrpc \
    soap \
    zip \
    intl \
    opcache

# Install additional PHP extensions
RUN pecl install redis && docker-php-ext-enable redis

# Configure PHP
RUN { \
    echo 'memory_limit = 512M'; \
    echo 'max_execution_time = 300'; \
    echo 'max_input_vars = 5000'; \
    echo 'post_max_size = 100M'; \
    echo 'upload_max_filesize = 100M'; \
    echo 'max_file_uploads = 20'; \
    echo 'date.timezone = UTC'; \
    echo 'opcache.enable = 1'; \
    echo 'opcache.memory_consumption = 128'; \
    echo 'opcache.interned_strings_buffer = 8'; \
    echo 'opcache.max_accelerated_files = 4000'; \
    echo 'opcache.revalidate_freq = 2'; \
    echo 'opcache.fast_shutdown = 1'; \
} > /usr/local/etc/php/conf.d/moodle.ini

# Configure Apache
RUN a2enmod rewrite headers expires

# Set Apache document root
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Create moodle user and group
RUN groupadd -r moodle && useradd -r -g moodle moodle

# Create necessary directories
RUN mkdir -p /var/www/html /var/www/moodledata /var/www/backups

# Copy Moodle code from the local repository into the image
COPY . /var/www/html/

# (Recommended) Use a .dockerignore file to exclude files/folders you don't want in the image, e.g. .git, moodledata, node_modules, etc.

# Set proper permissions
RUN chown -R moodle:moodle /var/www/html /var/www/moodledata /var/www/backups \
    && chmod -R 755 /var/www/html \
    && chmod -R 777 /var/www/moodledata

# Create Apache virtual host configuration
RUN echo '<VirtualHost *:80>\n\
    DocumentRoot /var/www/html\n\
    ServerName localhost\n\
    <Directory /var/www/html>\n\
        Options Indexes FollowSymLinks\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
    ErrorLog ${APACHE_LOG_DIR}/error.log\n\
    CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Expose port 80
EXPOSE 80

# Set working directory
WORKDIR /var/www/html

# Switch to moodle user
USER moodle

# Entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"] 