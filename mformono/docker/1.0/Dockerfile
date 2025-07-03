# syntax=docker/dockerfile:1

# See: https://php.watch/versions
ARG PHP_VERSION=8.4.8

# User and group settings
ARG APP_UID=1000
ARG APP_GID=${APP_UID}

#######
# App #
#######

FROM php:${PHP_VERSION}-fpm-bookworm AS app

# See: https://nodejs.org/en/about/previous-releases
ARG NODE_VERSION=24.3.0
# See: https://github.com/composer/composer/releases
ARG COMPOSER_VERSION=2.8.9
# See: https://github.com/mlocati/docker-php-extension-installer/releases
ARG PHP_EXTENSION_INSTALLER_VERSION=2.8.2

# OpenContainers labels
LABEL org.opencontainers.image.title="MforMono Skeleton"
LABEL org.opencontainers.image.description="A customised Symfony project to create bare bones applications with php recipes"
LABEL org.opencontainers.image.authors="Alexandre Balmes"
LABEL org.opencontainers.image.source="https://github.com/mformono/skeleton"

# User and group settings (must be redeclared after FROM)
ARG APP_UID
ARG APP_GID

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]

# Install system packages
RUN <<EOF

# Node Repository
curl -sSLf https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    --output /etc/apt/keyrings/node.asc
printf "\
Types: deb\n\
URIs: https://deb.nodesource.com/node_$(echo ${NODE_VERSION} | cut -d. -f1).x\n\
Suites: nodistro\n\
Components: main\n\
Signed-By: /etc/apt/keyrings/node.asc\n\
" > /etc/apt/sources.list.d/node.sources
printf "\
Package: nodejs\n\
Pin: version ${NODE_VERSION}-*\n\
Pin-Priority: 1000\n\
" > /etc/apt/preferences.d/node

apt-get update --quiet
apt-get upgrade --quiet --yes --purge
apt-get install --quiet --yes --no-install-recommends --verbose-versions \
    bash \
    dumb-init \
    git \
    nodejs \
    npm \
    sudo \
    wget \
    zip \
    unzip
apt-get clean
rm -rf /var/lib/apt/lists/*

# Create app user and group
addgroup --gid ${APP_GID} app
adduser --home /home/app --shell /bin/bash --uid ${APP_UID} --gecos app --ingroup app --disabled-password app

# Add app user to sudoers
echo "app ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/app

# App
install --verbose --owner app --group app --mode 0755 --directory /app

# Install PHP extensions installer
curl -sSLf https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    --output /usr/local/bin/install-php-extensions

chmod +x /usr/local/bin/install-php-extensions

# Install PHP extensions
install-php-extensions \
    @composer-${COMPOSER_VERSION} \
    intl \
    opcache \
    pcntl \
    xsl \
    zip
EOF

###> recipes ###
###< recipes ###

# Set working directory
WORKDIR /app

# Official php images comes with SIGQUIT as stop signal to shut down fpm gracefully (see: https://github.com/docker-library/php/pull/816)
# For a more generic way to use this image, set the default SIGTERM docker stop signal.
STOPSIGNAL SIGTERM

# Copy entrypoint scripts
COPY --link --chmod=755 etc/docker/entrypoints/* /usr/local/bin/
ENTRYPOINT ["app-entrypoint"]

#############
# App - Dev #
#############

FROM app AS app_dev

# Install Xdebug
RUN <<EOF
    install-php-extensions xdebug
EOF

# Set Xdebug mode to off by default (can be enabled via docker-compose)
ENV XDEBUG_MODE="off"

# Install Symfony CLI for development using heredoc
RUN <<EOF
    wget https://get.symfony.com/cli/installer -O - | bash
    mv /root/.symfony5/bin/symfony /usr/local/bin/symfony
    chown app:app /usr/local/bin/symfony
EOF

USER app

##############
# App - Prod #
##############

FROM app AS app_prod

ENV APP_ENV=prod

