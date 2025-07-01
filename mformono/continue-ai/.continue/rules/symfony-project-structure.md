---
globs: src/**/*.php
description: Rules for maintaining proper Symfony project structure following DDD principles
---

# Symfony Project Structure

- Organize code by business contexts following DDD/Hexagonal Architecture. 
- Never create Controller/, Entity/, Repository/ directories at the root of src/. 
- Always organize code within context directories (e.g., src/UserContext/, src/BillingContext/) with layers: Application/, Domain/, Infrastructure/, and UI/.