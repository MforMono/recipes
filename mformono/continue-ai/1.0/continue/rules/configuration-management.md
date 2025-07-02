---
globs: config/**/*.yaml,config/**/*.php,.env*
description: Guidelines for managing project configuration and secrets
---

# Configuration Management

- Use .env files and environment variables to manage sensitive configurations. 
- Never store secrets in the code. 
- Configure services, routes, and bundles in the config/ directory.