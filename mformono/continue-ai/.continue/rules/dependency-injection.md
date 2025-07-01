---
globs: src/**/*.php,config/**/*.php
description: Rules for managing dependencies and service configuration
---

# Dependency Injection

- Use Composer to add, update, or remove PHP dependencies.
- Systematically use Symfony's dependency injection with constructor injection. 
- Take advantage of autowiring and autoconfiguration. Only manually configure services in config/services.php for specific cases.