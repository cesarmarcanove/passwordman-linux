#!/bin/bash

# Password Policy Manager - Multi-Distribution v2.3
# TUI interface using Whiptail

# Configuración global
LOG_FILE="/var/log/password-policy.log"
BACKUP_DIR="/etc/security/backup"
CONFIG_FILE="/etc/security/password-policy.conf"
LOCALE_DIR="/usr/local/share/password-manager/locales"

# Cambio de idiomas | Change Language
CURRENT_LANG="es_ES" # Español
#CURRENT_LANG="en_US" # English
#CURRENT_LANG="de_VE" # Deutsch 

# Inicializar variables de traducción (valores por defecto en español)
initialize_translations() {
    # Variables principales del menú
    TITLE="Gestor de Políticas de Contraseñas v2.3"
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
    MENU_CHANGE_PASS="Cambiar contraseña de usuario"
    MENU_CHANGE_ROOT_PASS="Cambiar contraseña de root"
    MENU_ABOUT="Acerca de"
    MENU_LOG="Ver log de actividades"
    MENU_EXIT="Salir"

    # Cambiar contraseña
    CHANGE_PASS_TITLE="Cambiar Contraseña"
    CHANGE_PASS_USER="Seleccione el usuario:"
    CHANGE_PASS_NEW="Ingrese nueva contraseña:"
    CHANGE_PASS_CONFIRM="Confirme la contraseña:"
    CHANGE_PASS_ROOT_WARNING="¡ADVERTENCIA! Está cambiando la contraseña de root."
    CHANGE_PASS_SUCCESS="✓ Contraseña cambiada exitosamente para: %s"
    CHANGE_PASS_MISMATCH="✗ Las contraseñas no coinciden"
    CHANGE_PASS_EMPTY="✗ La contraseña no puede estar vacía"
    CHANGE_PASS_WEAK="✗ Contraseña muy débil. Use una más segura"
    CHANGE_PASS_ERROR="✗ Error al cambiar contraseña"

    # Acerca de
    ABOUT_TITLE="Acerca de v2.3"
    ABOUT_TEXT="Gestor Universal de Políticas de Contraseñas\n\nVersión: 2.3\nSoporte multi-distribución\nSoporte multi-idioma\nFunciones completas de gestión\n\nDesarrollado para Linux"

    # Bienvenida
    WELCOME_TITLE="Bienvenido al Gestor v2.3"
    WELCOME_MSG="GESTOR DE POLÍTICAS DE CONTRASEÑAS v2.3\n\nDistribución: %s\nIdioma: Español\n\nCaracterísticas:\n• Gestión de políticas\n• Cambio de contraseñas\n• Multi-idioma\n• Backup y restore"

    # Mensajes del sistema
    SUCCESS_TITLE="Éxito"
    ERROR_TITLE="Error"
    WARNING_TITLE="Advertencia"
    INFO_TITLE="Información"
}

# Cargar traducciones
load_translations() {
    local lang_file="$LOCALE_DIR/$CURRENT_LANG/strings.sh"
    
    # Si no existe el archivo de idioma, usar valores por defecto
    if [[ ! -f "$lang_file" ]]; then
        echo "Advertencia: Archivo de idioma $lang_file no encontrado. Usando valores por defecto."
        initialize_translations
        return 0
    fi
    
    # Cargar el archivo de idioma
    source "$lang_file" 2>/dev/null || {
        echo "Error: No se pudo cargar el archivo de idioma $lang_file"
        initialize_translations
    }
}

# Detectar distribución
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO=$ID
        DISTRO_NAME=$NAME
    elif [[ -f /etc/redhat-release ]]; then
        DISTRO="rhel"
        DISTRO_NAME=$(cat /etc/redhat-release)
    elif [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
        DISTRO_NAME="Debian $(cat /etc/debian_version)"
    else
        DISTRO="unknown"
        DISTRO_NAME="Unknown Distribution"
    fi
}

# Configuración específica por distribución
setup_distro_config() {
    case $DISTRO in
        manjaro|arch)
            LOGIN_DEFS="/etc/login.defs"
            PAM_PWQUALITY="/etc/security/pwquality.conf"
            ;;
        debian|devuan|ubuntu|linuxmint)
            LOGIN_DEFS="/etc/login.defs"
            PAM_PWQUALITY="/etc/pam.d/common-password"
            ;;
        fedora|centos|rhel)
            LOGIN_DEFS="/etc/login.defs"
            PAM_PWQUALITY="/etc/security/pwquality.conf"
            ;;
        opensuse|suse)
            LOGIN_DEFS="/etc/login.defs"
            PAM_PWQUALITY="/etc/security/pam_pwcheck.conf"
            ;;
        *)
            LOGIN_DEFS="/etc/login.defs"
            PAM_PWQUALITY="/etc/security/pwquality.conf"
            ;;
    esac
}

# Verificar si es root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Este script requiere privilegios de root. Ejecuta con sudo."
        exit 1
    fi
}

# Verificar compatibilidad
check_compatibility() {
    if ! command -v whiptail &> /dev/null; then
        echo "Error: 'whiptail' no está instalado."
        return 1
    fi
    
    if ! command -v chage &> /dev/null; then
        echo "Error: 'chage' no está instalado."
        return 1
    fi
    
    if ! command -v passwd &> /dev/null; then
        echo "Error: 'passwd' no está instalado."
        return 1
    fi
    
    return 0
}

# Instalar dependencias faltantes
install_dependencies() {
    case $DISTRO in
        manjaro|arch)
            pacman -Sy --noconfirm libnewt dialog
            ;;
        debian|ubuntu|linuxmint)
            apt-get update && apt-get install -y whiptail dialog
            ;;
        fedora|centos|rhel)
            yum install -y newt dialog
            ;;
        opensuse|suse)
            zypper install -y newt dialog
            ;;
    esac
}

# Función para cambiar contraseña de usuario
change_user_password() {
    local users=$(getent passwd | grep -v "/nologin\|/false" | cut -d: -f1 | sort | head -15)
    local user_list=""
    
    # Crear lista de usuarios
    for user in $users; do
        user_list+="$user \"Usuario $user\" "
    done
    
    local selected_user=$(whiptail --title "$CHANGE_PASS_TITLE" --menu \
        "$CHANGE_PASS_USER" 20 60 10 $user_list 3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 || -z "$selected_user" ]]; then
        return 1
    fi
    
    # Verificar si es root
    if [[ "$selected_user" == "root" ]]; then
        whiptail --title "$WARNING_TITLE" --msgbox "$CHANGE_PASS_ROOT_WARNING" 10 60
    fi
    
    # Solicitar nueva contraseña
    local password1=$(whiptail --title "$CHANGE_PASS_TITLE - $selected_user" \
        --passwordbox "$CHANGE_PASS_NEW" 10 60 3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 || -z "$password1" ]]; then
        whiptail --title "$ERROR_TITLE" --msgbox "$CHANGE_PASS_EMPTY" 8 50
        return 1
    fi
    
    # Verificar fortaleza básica
    if [[ ${#password1} -lt 3 ]]; then
        whiptail --title "$ERROR_TITLE" --msgbox "$CHANGE_PASS_WEAK" 8 50
        return 1
    fi
    
    # Confirmar contraseña
    local password2=$(whiptail --title "$CHANGE_PASS_TITLE - $selected_user" \
        --passwordbox "$CHANGE_PASS_CONFIRM" 10 60 3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # Verificar coincidencia
    if [[ "$password1" != "$password2" ]]; then
        whiptail --title "$ERROR_TITLE" --msgbox "$CHANGE_PASS_MISMATCH" 8 50
        return 1
    fi
    
    # Cambiar contraseña
    echo "$selected_user:$password1" | chpasswd
    
    if [[ $? -eq 0 ]]; then
        # Log del cambio
        log_action "CONTRASEÑA CAMBIADA - Usuario: $selected_user"
        
        whiptail --title "$SUCCESS_TITLE" --msgbox \
            "$(printf "$CHANGE_PASS_SUCCESS" "$selected_user")" 10 60
        return 0
    else
        whiptail --title "$ERROR_TITLE" --msgbox "$CHANGE_PASS_ERROR" 8 50
        return 1
    fi
}

# Función para cambiar contraseña de root
change_root_password() {
    whiptail --title "$WARNING_TITLE" --yesno \
        "¿Está seguro de cambiar la contraseña de root?\n\nEsta es una operación crítica del sistema." \
        12 60
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # Solicitar nueva contraseña para root
    local password1=$(whiptail --title "Cambiar Contraseña de ROOT" \
        --passwordbox "INGRESE NUEVA CONTRASEÑA PARA ROOT:\n\nUse una contraseña segura y memorable." \
        12 60 3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 || -z "$password1" ]]; then
        whiptail --title "$ERROR_TITLE" --msgbox "La contraseña de root no puede estar vacía" 8 50
        return 1
    fi
    
    # Verificar fortaleza mínima
    if [[ ${#password1} -lt 6 ]]; then
        whiptail --title "$ERROR_TITLE" --msgbox "Contraseña muy corta para root. Mínimo 6 caracteres." 8 50
        return 1
    fi
    
    # Confirmar contraseña
    local password2=$(whiptail --title "Confirmar Contraseña de ROOT" \
        --passwordbox "CONFIRME LA CONTRASEÑA PARA ROOT:" \
        10 60 3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # Verificar coincidencia
    if [[ "$password1" != "$password2" ]]; then
        whiptail --title "$ERROR_TITLE" --msgbox "Las contraseñas de root no coinciden" 8 50
        return 1
    fi
    
    # Cambiar contraseña de root
    echo "root:$password1" | chpasswd
    
    if [[ $? -eq 0 ]]; then
        # Log del cambio crítico
        log_action "CONTRASEÑA ROOT CAMBIADA - Operación crítica completada"
        
        whiptail --title "$SUCCESS_TITLE" --msgbox \
            "✓ CONTRASEÑA DE ROOT CAMBIADA EXITOSAMENTE\n\nGuarde la nueva contraseña en un lugar seguro." \
            12 60
        return 0
    else
        whiptail --title "$ERROR_TITLE" --msgbox "✗ ERROR AL CAMBIAR CONTRASEÑA DE ROOT" 8 50
        return 1
    fi
}


# Mostrar información de la distribución
show_distro_info() {
    whiptail --title "$MENU_SYSINFO" --msgbox \
    "=== INFORMACIÓN DEL SISTEMA ===\n\n\
Distribución: $DISTRO_NAME\n\
Configuración:\n\
• login.defs: $LOGIN_DEFS\n\
• PAM: $PAM_PWQUALITY\n\
Idioma: $CURRENT_LANG\n\
Versión: 2.3" 14 60
}

# Mostrar configuración actual
show_current_config() {
    local current_pass_max_days=$(grep "^PASS_MAX_DAYS" /etc/login.defs 2>/dev/null | awk '{print $2}')
    local current_pass_min_days=$(grep "^PASS_MIN_DAYS" /etc/login.defs 2>/dev/null | awk '{print $2}')
    local current_pass_warn_age=$(grep "^PASS_WARN_AGE" /etc/login.defs 2>/dev/null | awk '{print $2}')
    
    whiptail --title "$MENU_VIEW_CURRENT" --msgbox \
    "=== CONFIGURACIÓN ACTUAL ===\n\n\
Políticas de Contraseñas:\n\
• Días máximos: ${current_pass_max_days:-No configurado}\n\
• Días mínimos: ${current_pass_min_days:-No configurado}\n\
• Días de aviso: ${current_pass_warn_age:-No configurado}" 12 60
}

# Configurar política por defecto
set_default_policy() {
    local days=$(whiptail --title "$MENU_SET_DEFAULT" --inputbox \
    "Ingrese días para vencimiento de contraseñas (nuevos usuarios):" 10 60 "90" 3>&1 1>&2 2>&3)
    
    if [[ $? -eq 0 && -n "$days" ]]; then
        if [[ "$days" =~ ^[0-9]+$ ]] && [[ $days -gt 0 ]]; then
            if grep -q "^PASS_MAX_DAYS" /etc/login.defs; then
                sed -i "s/^PASS_MAX_DAYS.*/PASS_MAX_DAYS $days/" /etc/login.defs
            else
                echo "PASS_MAX_DAYS $days" >> /etc/login.defs
            fi
            
            log_action "Política por defecto actualizada: $days días"
            whiptail --title "$SUCCESS_TITLE" --msgbox "✓ Política actualizada a $days días." 8 50
        else
            whiptail --title "$ERROR_TITLE" --msgbox "✗ Ingrese un número válido mayor a 0." 8 50
        fi
    fi
}

# Configurar política para usuario específico
set_user_policy() {
    local users=$(getent passwd | grep -v "/nologin\|/false" | cut -d: -f1 | sort | head -10)
    local user_list=""
    
    for user in $users; do
        local current_days=$(chage -l "$user" 2>/dev/null | grep "Maximum" | awk -F: '{print $2}' | tr -d ' ')
        user_list+="$user \"Actual: $current_days días\" "
    done
    
    local selected_user=$(whiptail --title "$MENU_SET_USER" --menu \
    "Seleccione usuario para modificar:" 20 60 10 $user_list 3>&1 1>&2 2>&3)
    
    if [[ $? -eq 0 && -n "$selected_user" ]]; then
        local new_days=$(whiptail --title "Configurar Vencimiento" --inputbox \
        "Ingrese nuevos días de vencimiento para $selected_user:" 10 60 "" 3>&1 1>&2 2>&3)
        
        if [[ $? -eq 0 && -n "$new_days" ]]; then
            if [[ "$new_days" =~ ^[0-9]+$ ]] && [[ $new_days -gt 0 ]]; then
                chage -M "$new_days" "$selected_user"
                log_action "Usuario $selected_user - Vencimiento actualizado: $new_days días"
                whiptail --title "$SUCCESS_TITLE" --msgbox "✓ Vencimiento para $selected_user actualizado a $new_days días." 8 60
            else
                whiptail --title "$ERROR_TITLE" --msgbox "✗ Ingrese un número válido mayor a 0." 8 50
            fi
        fi
    fi
}

# Ver estado de usuarios
check_user_status() {
    local users=$(getent passwd | grep -v "/nologin\|/false" | cut -d: -f1 | sort | head -8)
    local status_report="=== ESTADO DE USUARIOS ===\n\n"
    
    for user in $users; do
        local user_info=$(chage -l "$user" 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            local max_days=$(echo "$user_info" | grep "Maximum" | awk -F: '{print $2}' | tr -d ' ')
            local last_change=$(echo "$user_info" | grep "Last password change" | awk -F: '{print $2}' | tr -d ' ')
            status_report+="🔹 $user:\n"
            status_report+="   Máximo: $max_days días\n"
            status_report+="   Último cambio: $last_change\n\n"
        fi
    done
    
    echo -e "$status_report" > /tmp/password_status.txt
    whiptail --title "$MENU_USER_STATUS" --scrolltext --textbox /tmp/password_status.txt 20 70
    rm -f /tmp/password_status.txt
}

# Crear backup
create_backup() {
    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/login.defs.backup.$(date +%Y%m%d_%H%M%S)"
    cp /etc/login.defs "$backup_file"
    log_action "Backup creado: $backup_file"
    whiptail --title "$SUCCESS_TITLE" --msgbox "✓ Backup creado exitosamente en:\n$backup_file" 10 60
}

# Función About
show_about() {
    whiptail --title "$ABOUT_TITLE" --msgbox "$ABOUT_TEXT" 15 70
}

# Log de actividades
log_action() {
    echo "[v2.3] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Menú principal MEJORADO
main_menu() {
    while true; do
        local choice=$(whiptail --title "$TITLE" --menu \
            "=== GESTOR v2.3 ===\nDistribución: $DISTRO_NAME\nIdioma: $CURRENT_LANG\n\nSeleccione opción:" \
            22 70 12 \
            "1" "$MENU_VIEW_CURRENT" \
            "2" "$MENU_SET_DEFAULT" \
            "3" "$MENU_SET_USER" \
            "4" "$MENU_USER_STATUS" \
            "5" "$MENU_CHANGE_PASS" \
            "6" "$MENU_CHANGE_ROOT_PASS" \
            "7" "$MENU_BACKUP" \
            "8" "$MENU_SYSINFO" \
            "9" "$MENU_ABOUT" \
            "L" "🌐 $LANG_SELECT_TITLE" \
            "0" "$MENU_EXIT" \
            3>&1 1>&2 2>&3)

        case $choice in
            1) show_current_config ;;
            2) set_default_policy ;;
            3) set_user_policy ;;
            4) check_user_status ;;
            5) change_user_password ;;
            6) change_root_password ;;
            7) create_backup ;;
            8) show_distro_info ;;
            9) show_about ;;
            L) select_language ;;
            0) break ;;
            *) break ;;
        esac
    done
}

# Inicialización del sistema
initialize_system() {
    check_root
    detect_distro
    setup_distro_config
    
    # Inicializar traducciones primero
    initialize_translations
    
    # Luego cargar desde archivo si existe
    load_translations
    
    # Verificar dependencias
    if ! check_compatibility; then
        echo "Instalando dependencias faltantes..."
        install_dependencies
    fi
    
    # Crear directorios necesarios
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    
    # Log de inicio
    log_action "Sistema inicializado - Distribución: $DISTRO_NAME"
}

# Mensaje de bienvenida
show_welcome() {
    whiptail --title "$WELCOME_TITLE" --msgbox \
    "$(printf "$WELCOME_MSG" "$DISTRO_NAME")" 14 65
}

# Main execution
initialize_system
show_welcome
main_menu

whiptail --title "Gestor Finalizado" --msgbox "✓ Gestor de Contraseñas v2.3 finalizado\n\nDistribución: $DISTRO_NAME\nIdioma: $CURRENT_LANG\nLog: $LOG_FILE" 12 60
