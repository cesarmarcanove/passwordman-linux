# Gestor de Políticas de Contraseñas v2.3

## 📋 Descripción

El **Gestor de Políticas de Contraseñas** es una aplicación de línea de comandos diseñada para administrar y configurar políticas de seguridad de contraseñas en sistemas Linux. Desarrollado con soporte multi-distribución y multi-idioma, ofrece una interfaz intuitiva para la gestión completa de políticas de seguridad.

## 🚀 Características Principales

### Gestión de Políticas
- Configuración de políticas por defecto para nuevos usuarios
- Políticas específicas por usuario
- Visualización del estado actual de configuración
- Aplicación de políticas a todos los usuarios

### Gestión de Contraseñas
- Cambio de contraseñas de usuario
- Cambio seguro de contraseña de root
- Verificación de complejidad de contraseñas
- Monitoreo de vencimiento de contraseñas

### Funciones de Seguridad
- Creación de backups de configuración
- Restauración de backups
- Log de actividades del sistema
- Verificación de políticas de seguridad

## 🆕 Novedades v2.3

### Soporte Multi-Idioma
- **+45 idiomas** incluidos
- Soporte para variantes regionales
- Incluye soporte para caracteres runicas tipo Futhark: alemán, sueco, noruego y islandés (ejm: "ᛁᚾᚠᛟᚱᛗᚨᛏᛁᛟᚾ" en alemán rúnico)
- Traducciones completas de la interfaz
- Fácil cambio entre idiomas

### Distribuciones Soportadas
- **Modernas**: Ubuntu, Debian, Fedora, CentOS, Arch, Manjaro, openSUSE
- **Históricas**: Mandriva, Mandrake, Slackware, Gentoo
- **Especializadas**: Alpine, Void, OpenMandriva, Mageia

### Mejoras Técnicas
- Detección automática de distribución
- Instalación automática de dependencias
- Soporte para instalación offline
- Interfaz optimizada para TUI

## USO
- Versión simple: sudo password-policy-manager
- Versión extendida: sudo password-policy-manager-all

## 🌍 Cambio de Idioma

### Configuración Manual
Edite la variable `CURRENT_LANG` en los archivos principales:

```bash
# En /usr/local/bin/password-policy-manager
# En /usr/local/bin/password-policy-manager-all
```

# Cambio de idiomas | Change Language
CURRENT_LANG="es_ES" # Español

# Para inglés americano
CURRENT_LANG="en_US"

# Para inglés británico  
CURRENT_LANG="en_GB"

# Para francés
CURRENT_LANG="fr_FR"

# Para alemán
CURRENT_LANG="de_DE"

variantes: de_VE, de_DE_runes

# Para italiano
CURRENT_LANG="it_IT"

variantes: it_VE, it_AR, it_US, it_LA

# Para ucraniano (Slava Ukraini)
CURRENT_LANG="uk_UA"

## LICENCIA

GPL v2.0 License - Ver archivo LICENSE para detalles completos.

Se concede permiso para usar, copiar, modificar y distribuir este software
sin restricciones, siempre que se incluya el aviso de copyright.

## COPYRIGHT

Copyright (c) 2024 Gestor de Políticas de Contraseñas
Todos los derechos reservados según los términos de la GPL v2.0.

### CONTACTO Y SOPORTE

Para reportar issues o solicitar características, crear un issue en el
repositorio del proyecto incluyendo información de la distribución y
versión del sistema.

### Versión: 2.3
Actualización: Octubre del 2025

Soporte: Sistemas Linux Multi-Distribución
