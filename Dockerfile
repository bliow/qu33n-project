FROM php:7.3.8-apache
# We could use `httpd:2.4`, as we don't need PHP right now, but the config files
# in that image are in a different place. This is easier in the long run.

LABEL maintainer="Rafi Laksmana"

# Install Composer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
       && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
       && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) \
!== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); \
echo 'Invalid installer' . PHP_EOL; exit(1); }" \
       && php /tmp/composer-setup.php \
            --no-ansi \
            --install-dir=/usr/local/bin \
            --filename=composer \
            --snapshot \
       && rm -f /tmp/composer-setup.*

# Install unzip utils (used by Composer) ...
# ... install PHP's MySQL PDO drivers
# ... and run our composer-install script
RUN apt-get -yqq update \
    && apt-get -yqq install --no-install-recommends unzip \
    && docker-php-ext-install pdo_mysql \
    && chmod +x /usr/local/bin/composer \
    && composer --version

COPY ./app /srv/app

# Run Composer to install dependancies
WORKDIR /srv/app/
RUN composer install \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist

# PHP configuration
# This needs to be set *after* composer install, because
# we use auto-prepend
COPY docker/php/php.ini /usr/local/etc/php/php.ini

# The destination directory will need to change, based on the image,
# because the config files are put in different places in different images
COPY docker/apache/vhost.conf /etc/apache2/sites-available/000-default.conf
