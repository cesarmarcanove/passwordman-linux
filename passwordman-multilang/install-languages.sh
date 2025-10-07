#!/bin/bash
# install-languages.sh

LOCALE_DIR="/usr/local/share/password-manager/locales"

create_spanish_translation() {
    mkdir -p "$LOCALE_DIR/es_ES"
    cat > "$LOCALE_DIR/es_ES/strings.sh" << 'EOF'
#!/bin/bash
# Spanish Translations

TITLE="Gestor de Políticas de Contraseñas"
MENU_VIEW_CURRENT="Ver configuración actual"
MENU_SET_DEFAULT="Configurar política por defecto"
MENU_SET_USER="Configurar política para usuario"
MENU_ADVANCED="Configuración avanzada"
MENU_USER_STATUS="Ver estado de usuarios"
MENU_APPLY_ALL="Aplicar a todos los usuarios"
MENU_SECURITY="Ver políticas de seguridad"
MENU_BACKUP="Crear backup"
MENU_RESTORE="Restaurar backup"
MENU_SYSINFO="Información del sistema"
MENU_COMPLEXITY="Complejidad de contraseñas"
MENU_CHANGE_PASS="Cambiar contraseña"
MENU_ABOUT="Acerca de"
MENU_LOG="Ver log de actividades"
MENU_EXIT="Salir"

CHANGE_PASS_TITLE="Cambiar Contraseña"
CHANGE_PASS_USER="Seleccione el usuario:"
CHANGE_PASS_NEW="Ingrese nueva contraseña:"
CHANGE_PASS_CONFIRM="Confirme la contraseña:"
CHANGE_PASS_ROOT_WARNING="¡Advertencia! Cambiando contraseña de root."
CHANGE_PASS_SUCCESS="Contraseña cambiada para: %s"
CHANGE_PASS_MISMATCH="Las contraseñas no coinciden"

ABOUT_TITLE="Acerca de"
ABOUT_TEXT="Gestor de Políticas de Contraseñas\nVersión: 2.0\nIdioma: Español"

WELCOME_TITLE="Bienvenido"
WELCOME_MSG="Gestor de Políticas de Contraseñas\nDistribución: %s\nIdioma: Español"

LANG_SELECT_TITLE="Selector de Idioma"
LANG_SELECT_PROMPT="Seleccione idioma:"
LANG_CHANGED_TITLE="Idioma Cambiado"
LANG_CHANGED_MSG="Idioma cambiado a: %s"
EOF
}

create_english_translation() {
    mkdir -p "$LOCALE_DIR/en_US"
    cat > "$LOCALE_DIR/en_US/strings.sh" << 'EOF'
#!/bin/bash
# English Translations

TITLE="Password Policy Manager"
MENU_VIEW_CURRENT="View current configuration"
MENU_SET_DEFAULT="Set default policy"
MENU_SET_USER="Set user policy"
MENU_ADVANCED="Advanced configuration"
MENU_USER_STATUS="View user status"
MENU_APPLY_ALL="Apply to all users"
MENU_SECURITY="View security policies"
MENU_BACKUP="Create backup"
MENU_RESTORE="Restore backup"
MENU_SYSINFO="System information"
MENU_COMPLEXITY="Password complexity"
MENU_CHANGE_PASS="Change password"
MENU_ABOUT="About"
MENU_LOG="View activity log"
MENU_EXIT="Exit"

CHANGE_PASS_TITLE="Change Password"
CHANGE_PASS_USER="Select user:"
CHANGE_PASS_NEW="Enter new password:"
CHANGE_PASS_CONFIRM="Confirm password:"
CHANGE_PASS_ROOT_WARNING="Warning! Changing root password."
CHANGE_PASS_SUCCESS="Password changed for: %s"
CHANGE_PASS_MISMATCH="Passwords do not match"

ABOUT_TITLE="About"
ABOUT_TEXT="Password Policy Manager\nVersion: 2.0\nLanguage: English"

WELCOME_TITLE="Welcome"
WELCOME_MSG="Password Policy Manager\nDistribution: %s\nLanguage: English"

LANG_SELECT_TITLE="Language Selector"
LANG_SELECT_PROMPT="Select language:"
LANG_CHANGED_TITLE="Language Changed"
LANG_CHANGED_MSG="Language changed to: %s"
EOF
}

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo "Ejecutar como root: sudo $0"
    exit 1
fi

# Crear directorio principal
mkdir -p "$LOCALE_DIR"

# Instalar idiomas
echo "Instalando idiomas..."
create_spanish_translation
create_english_translation

# Establecer permisos
chmod -R 755 "$LOCALE_DIR"

echo "Idiomas instalados en: $LOCALE_DIR"
echo "Idiomas disponibles:"
ls -la "$LOCALE_DIR"