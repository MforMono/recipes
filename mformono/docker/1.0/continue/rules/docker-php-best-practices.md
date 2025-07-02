---
globs: "*Dockerfile*,docker/php/**/*,docker/entrypoints/*,compose.yaml"
description: Specialized Docker conventions for PHP and Symfony applications.
  These rules ensure optimal PHP configuration, proper development and
  production environments, efficient dependency management, and adherence to
  Symfony best practices in containerized environments.
---

# PHP/Symfony Docker Best Practices

1. Use official PHP images as base (php:X.Y-fpm-distribution).
2. Use Debian-based images (bookworm) for better compatibility with PHP extensions.
3. Use install-php-extensions script for PHP extension installation.
4. Install specific PHP extensions required for Symfony:
   - intl: for internationalization
   - opcache: for performance optimization
   - pcntl: for process control
   - xsl: for XML transformations
   - zip: for package handling
5. Install composer with a pinned version using @composer-X.Y.Z syntax.
6. Install dev tools like Xdebug only in the development image.
7. Control Xdebug via environment variables (XDEBUG_MODE, XDEBUG_CLIENT_HOST, etc.).
8. Configure optimal PHP settings for development vs. production environments.
9. Move the production php.ini into place in the production image.
10. Configure opcache for production with:
    - opcache.validate_timestamps=0
    - opcache.memory_consumption=128
    - opcache.max_accelerated_files=10000
11. Install Symfony CLI only in the development image.
12. Use dumb-init to properly handle process signals in containerized PHP applications.
13. Implement a custom entrypoint that installs Composer and NPM dependencies if not present.
14. Mount custom PHP configuration files (like xdebug.ini) as read-only volumes.
15. Organize PHP configuration files in etc/docker/php/conf.d/ directory.
16. Set APP_ENV environment variable appropriately for each environment.