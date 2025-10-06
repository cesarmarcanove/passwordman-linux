#!/bin/bash

# Password Policy Manager - Multi-Distribution
# TUI interface using Whiptail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración global
LOG_FILE="/var/log/password-policy.log"
BACKUP_DIR="/etc/security/backup"
CONFIG_FILE="/etc/security/password-policy.conf"

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
        debian|devuan|canaima|ubuntu|xubuntu|kubuntu|edubuntu|lubuntu|mx-linux|linuxmint)
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
    
    # Configuración adicional específica
    case $DISTRO in
        debian|devuan|canaima|ubuntu|xubuntu|kubuntu|edubuntu|lubuntu|mx-linux|linuxmint)
            PAM_DIR="/etc/pam.d"
            ;;
        fedora|centos|rhel)
            PAM_DIR="/etc/pam.d"
            ;;
        *)
            PAM_DIR="/etc/pam.d"
            ;;
    esac
}

# Verificar si es root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        whiptail --title "Error de Permisos" --msgbox "Este script requiere privilegios de root. Ejecuta con sudo." 8 60
        exit 1
    fi
}

# Verificar compatibilidad
check_compatibility() {
    local missing_tools=()
    
    # Herramientas requeridas
    local required_tools=("whiptail" "chage" "getent" "sed" "grep")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        whiptail --title "Error de Compatibilidad" --msgbox \
        "Faltan herramientas requeridas: ${missing_tools[*]}\n\nInstálelas con el gestor de paquetes de su distribución." 12 60
        return 1
    fi
    
    return 0
}

# Instalar dependencias faltantes
install_dependencies() {
    case $DISTRO in
        manjaro|arch)
            if ! command -v whiptail &> /dev/null; then
                whiptail --title "Instalación" --msgbox \
                "Se instalará 'whiptail' (newt package)" 8 50
                pacman -Sy --noconfirm newt
            fi
            ;;
        debian|devuan|canaima|ubuntu|xubuntu|kubuntu|edubuntu|lubuntu|mx-linux|linuxmint)
            if ! command -v whiptail &> /dev/null; then
                whiptail --title "Instalación" --msgbox \
                "Se instalará 'whiptail' (whiptail package)" 8 50
                apt-get update && apt-get install -y whiptail
            fi
            ;;
        fedora|centos|rhel)
            if ! command -v whiptail &> /dev/null; then
                whiptail --title "Instalación" --msgbox \
                "Se instalará 'whiptail' (newt package)" 8 50
                yum install -y newt
            fi
            ;;
        opensuse|suse)
            if ! command -v whiptail &> /dev/null; then
                whiptail --title "Instalación" --msgbox \
                "Se instalará 'whiptail' (newt package)" 8 50
                zypper install -y newt
            fi
            ;;
    esac
}

# Configuración específica para PAM (Distros modernas)
setup_pam_config() {
    case $DISTRO in
        debian|devuan|canaima|ubuntu|xubuntu|kubuntu|edubuntu|lubuntu|mx-linux|linuxmint)
            if [[ -f "/etc/pam.d/common-password" ]]; then
                whiptail --title "Info PAM" --msgbox \
                "En Debian/Ubuntu, las políticas adicionales se configuran en:\n/etc/pam.d/common-password" 10 60
            fi
            ;;
        fedora|centos|rhel)
            if [[ -f "/etc/security/pwquality.conf" ]]; then
                whiptail --title "Info PAM" --msgbox \
                "En Fedora/RHEL, la calidad de contraseñas se configura en:\n/etc/security/pwquality.conf" 10 60
            fi
            ;;
    esac
}

# Mostrar información de la distribución
show_distro_info() {
    whiptail --title "Información del Sistema" --msgbox \
    "Distribución detectada: $DISTRO_NAME\n\n\
    Archivos de configuración:\n\
    • login.defs: $LOGIN_DEFS\n\
    • PAM: $PAM_PWQUALITY\n\
    • Directorio PAM: $PAM_DIR" 14 60
}

# Mostrar configuración actual
show_current_config() {
    local current_pass_max_days=$(grep "^PASS_MAX_DAYS" /etc/login.defs | awk '{print $2}')
    local current_pass_min_days=$(grep "^PASS_MIN_DAYS" /etc/login.defs | awk '{print $2}')
    local current_pass_warn_age=$(grep "^PASS_WARN_AGE" /etc/login.defs | awk '{print $2}')
    
    whiptail --title "Configuración Actual" --msgbox \
    "Configuración actual de políticas de contraseñas:\n\n\
    • Días máximos: ${current_pass_max_days:-No configurado}\n\
    • Días mínimos: ${current_pass_min_days:-No configurado}\n\
    • Días de aviso: ${current_pass_warn_age:-No configurado}" 12 60
}

# Configurar política por defecto
set_default_policy() {
    local days=$(whiptail --title "Política por Defecto" --inputbox \
    "Ingrese el número de días para vencimiento de contraseñas (para nuevos usuarios):" 10 60 "90" 3>&1 1>&2 2>&3)
    
    if [[ $? -eq 0 && -n "$days" ]]; then
        if [[ "$days" =~ ^[0-9]+$ ]] && [[ $days -gt 0 ]]; then
            # Actualizar login.defs
            sed -i "s/^PASS_MAX_DAYS.*/PASS_MAX_DAYS $days/" /etc/login.defs
            if ! grep -q "^PASS_MAX_DAYS" /etc/login.defs; then
                echo "PASS_MAX_DAYS $days" >> /etc/login.defs
            fi
            
            log_action "Política por defecto actualizada: PASS_MAX_DAYS=$days"
            whiptail --title "Éxito" --msgbox "Política por defecto actualizada a $days días." 8 50
        else
            whiptail --title "Error" --msgbox "Por favor ingrese un número válido mayor a 0." 8 50
        fi
    fi
}

# Configurar política para usuario específico
set_user_policy() {
    local users=$(getent passwd | grep -v "/nologin\|/false" | cut -d: -f1 | sort)
    local user_list=""
    
    # Crear lista de usuarios
    for user in $users; do
        local current_days=$(chage -l "$user" 2>/dev/null | grep "Maximum" | awk -F: '{print $2}' | tr -d ' ')
        user_list+="$user $current_days off "
    done
    
    local selected_user=$(whiptail --title "Seleccionar Usuario" --menu \
    "Seleccione el usuario para modificar:" 20 60 10 $user_list 3>&1 1>&2 2>&3)
    
    if [[ $? -eq 0 && -n "$selected_user" ]]; then
        local current_info=$(chage -l "$selected_user")
        local new_days=$(whiptail --title "Configurar Vencimiento" --inputbox \
        "Información actual del usuario $selected_user:\n\n$current_info\n\nIngrese nuevos días para vencimiento:" 20 80 "" 3>&1 1>&2 2>&3)
        
        if [[ $? -eq 0 && -n "$new_days" ]]; then
            if [[ "$new_days" =~ ^[0-9]+$ ]] && [[ $new_days -gt 0 ]]; then
                chage -M "$new_days" "$selected_user"
                log_action "Usuario $selected_user - Vencimiento actualizado a $new_days días"
                whiptail --title "Éxito" --msgbox "Vencimiento para $selected_user actualizado a $new_days días." 8 60
            else
                whiptail --title "Error" --msgbox "Por favor ingrese un número válido mayor a 0." 8 50
            fi
        fi
    fi
}

# Configurar política avanzada
set_advanced_policy() {
    local current_max=$(grep "^PASS_MAX_DAYS" /etc/login.defs | awk '{print $2}')
    local current_min=$(grep "^PASS_MIN_DAYS" /etc/login.defs | awk '{print $2}')
    local current_warn=$(grep "^PASS_WARN_AGE" /etc/login.defs | awk '{print $2}')
    
    local max_days=$(whiptail --title "Política Avanzada" --inputbox \
    "Días máximos (PASS_MAX_DAYS):" 10 60 "${current_max:-90}" 3>&1 1>&2 2>&3)
    
    local min_days=$(whiptail --title "Política Avanzada" --inputbox \
    "Días mínimos entre cambios (PASS_MIN_DAYS):" 10 60 "${current_min:-1}" 3>&1 1>&2 2>&3)
    
    local warn_days=$(whiptail --title "Política Avanzada" --inputbox \
    "Días de aviso previo (PASS_WARN_AGE):" 10 60 "${current_warn:-7}" 3>&1 1>&2 2>&3)
    
    if [[ $? -eq 0 ]]; then
        # Validar entradas
        if [[ "$max_days" =~ ^[0-9]+$ ]] && [[ "$min_days" =~ ^[0-9]+$ ]] && [[ "$warn_days" =~ ^[0-9]+$ ]]; then
            # Actualizar configuración
            update_login_defs "PASS_MAX_DAYS" "$max_days"
            update_login_defs "PASS_MIN_DAYS" "$min_days"
            update_login_defs "PASS_WARN_AGE" "$warn_days"
            
            log_action "Política avanzada actualizada: MAX=$max_days, MIN=$min_days, WARN=$warn_days"
            whiptail --title "Éxito" --msgbox "Política avanzada actualizada exitosamente." 8 50
        else
            whiptail --title "Error" --msgbox "Por favor ingrese valores numéricos válidos." 8 50
        fi
    fi
}

# Función auxiliar para actualizar login.defs
update_login_defs() {
    local key="$1"
    local value="$2"
    
    if grep -q "^$key" /etc/login.defs; then
        sed -i "s/^$key.*/$key $value/" /etc/login.defs
    else
        echo "$key $value" >> /etc/login.defs
    fi
}

# Ver estado de usuarios
check_user_status() {
    local users=$(getent passwd | grep -v "/nologin\|/false" | cut -d: -f1 | sort)
    local status_report="Estado de vencimiento de contraseñas:\n\n"
    
    for user in $users; do
        local user_info=$(chage -l "$user" 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            local max_days=$(echo "$user_info" | grep "Maximum" | awk -F: '{print $2}' | tr -d ' ')
            local last_change=$(echo "$user_info" | grep "Last password change" | awk -F: '{print $2}' | tr -d ' ')
            local expires=$(echo "$user_info" | grep "Password expires" | awk -F: '{print $2}' | tr -d ' ')
            
            status_report+="Usuario: $user\n"
            status_report+="• Máximo: $max_days días\n"
            status_report+="• Último cambio: $last_change\n"
            status_report+="• Expira: $expires\n\n"
        fi
    done
    
    echo -e "$status_report" > /tmp/password_status.txt
    whiptail --title "Estado de Usuarios" --scrolltext --textbox /tmp/password_status.txt 20 80
    rm -f /tmp/password_status.txt
}

# Aplicar política a todos los usuarios
apply_to_all_users() {
    local max_days=$(grep "^PASS_MAX_DAYS" /etc/login.defs | awk '{print $2}')
    
    if [[ -z "$max_days" ]]; then
        whiptail --title "Error" --msgbox "No hay política de días máximos configurada." 8 50
        return
    fi
    
    if whiptail --title "Confirmación" --yesno \
    "¿Está seguro de aplicar la política de $max_days días a TODOS los usuarios?\n\nEsta acción no se puede deshacer fácilmente." 12 60; then
        
        local users=$(getent passwd | grep -v "/nologin\|/false" | cut -d: -f1)
        local updated_count=0
        
        for user in $users; do
            if chage -M "$max_days" "$user" 2>/dev/null; then
                ((updated_count++))
            fi
        done
        
        log_action "Política aplicada a $updated_count usuarios: PASS_MAX_DAYS=$max_days"
        whiptail --title "Éxito" --msgbox "Política aplicada a $updated_count usuarios exitosamente." 8 60
    fi
}

# Crear directorio de backup
create_backup() {
    mkdir -p "$BACKUP_DIR"
    cp /etc/login.defs "$BACKUP_DIR/login.defs.backup.$(date +%Y%m%d_%H%M%S)"
    whiptail --title "Backup" --msgbox "Backup creado exitosamente en $BACKUP_DIR" 8 50
}

# Log de actividades
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Restaurar backup
restore_backup() {
    local backups=$(ls -1 "$BACKUP_DIR"/login.defs.backup.* 2>/dev/null)
    
    if [[ -z "$backups" ]]; then
        whiptail --title "Error" --msgbox "No hay backups disponibles." 8 50
        return
    fi
    
    local backup_list=""
    for backup in $backups; do
        local date=$(echo "$backup" | grep -o '[0-9]\{8\}_[0-9]\{6\}')
        backup_list+="$backup $date off "
    done
    
    local selected_backup=$(whiptail --title "Seleccionar Backup" --menu \
    "Seleccione el backup a restaurar:" 20 60 10 $backup_list 3>&1 1>&2 2>&3)
    
    if [[ $? -eq 0 && -n "$selected_backup" ]]; then
        if whiptail --title "Confirmar" --yesno "¿Restaurar backup $selected_backup?" 10 60; then
            cp "$selected_backup" /etc/login.defs
            log_action "Configuración restaurada desde: $selected_backup"
            whiptail --title "Éxito" --msgbox "Backup restaurado exitosamente." 8 50
        fi
    fi
}

# Mostrar log
show_log() {
    if [[ -f "$LOG_FILE" ]]; then
        whiptail --title "Log de Actividades" --scrolltext --textbox "$LOG_FILE" 20 80
    else
        whiptail --title "Error" --msgbox "No hay archivo de log disponible." 8 50
    fi
}

# Configuración de complejidad de contraseñas (PAM)
setup_password_complexity() {
    case $DISTRO in
        fedora|centos|rhel|manjaro|arch)
            setup_pwquality_complexity
            ;;
        debian|devuan|canaima|ubuntu|xubuntu|kubuntu|edubuntu|lubuntu|mx-linux|linuxmint)
            setup_pam_complexity_debian
            ;;
        *)
            whiptail --title "No Soportado" --msgbox \
            "Configuración de complejidad no automatizada para $DISTRO_NAME.\n\nConfigure manualmente en $PAM_PWQUALITY" 12 60
            ;;
    esac
}

# Configurar pwquality (Fedora/RHEL/Arch)
setup_pwquality_complexity() {
    if [[ -f "/etc/security/pwquality.conf" ]]; then
        local current_minlen=$(grep "^minlen" /etc/security/pwquality.conf | awk '{print $3}')
        local current_dcredit=$(grep "^dcredit" /etc/security/pwquality.conf | awk '{print $3}')
        local current_ucredit=$(grep "^ucredit" /etc/security/pwquality.conf | awk '{print $3}')
        local current_ocredit=$(grep "^ocredit" /etc/security/pwquality.conf | awk '{print $3}')
        local current_lcredit=$(grep "^lcredit" /etc/security/pwquality.conf | awk '{print $3}')
        
        local minlen=$(whiptail --title "Complejidad de Contraseñas" --inputbox \
        "Longitud mínima de contraseña:" 10 60 "${current_minlen:-8}" 3>&1 1>&2 2>&3)
        
        local dcredit=$(whiptail --title "Complejidad de Contraseñas" --inputbox \
        "Mínimo dígitos (-1 = al menos 1, 0 = ninguno requerido):" 10 60 "${current_dcredit:--1}" 3>&1 1>&2 2>&3)
        
        if [[ $? -eq 0 ]]; then
            # Backup
            cp /etc/security/pwquality.conf /etc/security/pwquality.conf.backup.$(date +%Y%m%d_%H%M%S)
            
            # Actualizar configuración
            [[ -n "$minlen" ]] && update_config_value "minlen" "$minlen" "/etc/security/pwquality.conf"
            [[ -n "$dcredit" ]] && update_config_value "dcredit" "$dcredit" "/etc/security/pwquality.conf"
            
            log_action "Complejidad PAM actualizada: minlen=$minlen, dcredit=$dcredit"
            whiptail --title "Éxito" --msgbox "Configuración de complejidad actualizada." 8 50
        fi
    else
        whiptail --title "No Soportado" --msgbox "pwquality.conf no encontrado en su distribución." 8 50
    fi
}

# Configurar complejidad PAM para Debian/Ubuntu
setup_pam_complexity_debian() {
    whiptail --title "Configuración Debian/Ubuntu" --msgbox \
    "En Debian/Ubuntu y derivados, la complejidad se configura en:\n\n\
    /etc/pam.d/common-password\n\n\
    Busque la línea que contiene 'pam_pwquality.so' o 'pam_cracklib.so'\n\
    y modifique los parámetros según necesite." 12 70
}

# Función auxiliar para actualizar valores de configuración
update_config_value() {
    local key="$1"
    local value="$2"
    local file="$3"
    
    if grep -q "^$key" "$file"; then
        sed -i "s/^$key.*/$key = $value/" "$file"
    else
        echo "$key = $value" >> "$file"
    fi
}

# Verificar políticas de seguridad adicionales
check_security_policies() {
    local security_info="Políticas de Seguridad - $DISTRO_NAME\n\n"
    
    # Verificar configuración de login.defs
    if [[ -f "$LOGIN_DEFS" ]]; then
        security_info+="=== login.defs ===\n"
        security_info+="PASS_MAX_DAYS: $(grep "^PASS_MAX_DAYS" "$LOGIN_DEFS" | awk '{print $2}')\n"
        security_info+="PASS_MIN_DAYS: $(grep "^PASS_MIN_DAYS" "$LOGIN_DEFS" | awk '{print $2}')\n"
        security_info+="PASS_WARN_AGE: $(grep "^PASS_WARN_AGE" "$LOGIN_DEFS" | awk '{print $2}')\n\n"
    fi
    
    # Verificar configuración PAM específica
    case $DISTRO in
        debian|devuan|canaima|ubuntu|xubuntu|kubuntu|edubuntu|lubuntu|mx-linux|linuxmint)
            if [[ -f "/etc/pam.d/common-password" ]]; then
                security_info+="=== PAM Common Password ===\n"
                security_info+="Configuración PAM encontrada\n"
            fi
            ;;
        fedora|centos|rhel)
            if [[ -f "/etc/security/pwquality.conf" ]]; then
                security_info+="=== pwquality.conf ===\n"
                security_info+="minlen: $(grep "^minlen" /etc/security/pwquality.conf | awk '{print $3}')\n"
            fi
            ;;
    esac
    
    echo -e "$security_info" > /tmp/security_policies.txt
    whiptail --title "Políticas de Seguridad" --scrolltext --textbox /tmp/security_policies.txt 20 80
    rm -f /tmp/security_policies.txt
}

# Menú extendido con opciones específicas por distribución
extended_main_menu() {
    while true; do
        local menu_text="Gestor de Políticas de Contraseñas\nDistribución: $DISTRO_NAME\n\nSeleccione una opción:"
        
        local choice=$(whiptail --title "Gestor Multi-Distro" --menu "$menu_text" 22 70 12 \
        "1" "Ver configuración actual" \
        "2" "Configurar política por defecto" \
        "3" "Configurar usuario específico" \
        "4" "Política avanzada" \
        "5" "Ver estado de usuarios" \
        "6" "Aplicar a todos los usuarios" \
        "7" "Ver políticas de seguridad" \
        "8" "Backup de configuración" \
        "9" "Restaurar configuración" \
        "A" "Ver información del sistema" \
        "C" "Configurar complejidad (PAM)" \
        "L" "Ver log de actividades" \
        "0" "Salir" 3>&1 1>&2 2>&3)
        
        case $choice in
            1) show_current_config ;;
            2) set_default_policy ;;
            3) set_user_policy ;;
            4) set_advanced_policy ;;
            5) check_user_status ;;
            6) apply_to_all_users ;;
            7) check_security_policies ;;
            8) create_backup ;;
            9) restore_backup ;;
            A) show_distro_info ;;
            C) setup_password_complexity ;;
            L) show_log ;;
            0) break ;;
            *) break ;;
        esac
    done
}

# Inicialización mejorada
enhanced_init() {
    check_root
    detect_distro
    setup_distro_config
    
    if ! check_compatibility; then
        if whiptail --title "Instalar Dependencias" --yesno \
        "¿Desea instalar las dependencias faltantes automáticamente?" 10 60; then
            install_dependencies
        else
            exit 1
        fi
    fi
    
    mkdir -p "$BACKUP_DIR"
    touch "$LOG_FILE"
}

# Mensaje de bienvenida multi-distro
multi_distro_welcome() {
    whiptail --title "Bienvenido" --msgbox \
    "Gestor Profesional de Políticas de Contraseñas\n\n\
    Distribución: $DISTRO_NAME\n\n\
    Características soportadas:\n\
    • Gestión de vencimiento de contraseñas\n\
    • Configuración multi-distribución\n\
    • Políticas PAM (según distribución)\n\
    • Backup y restauración\n\
    • Log de actividades" 16 60
}

# Main execution
enhanced_init
multi_distro_welcome
extended_main_menu

whiptail --title "Salida" --msgbox "¡Gestor de contraseñas finalizado!\nDistribución: $DISTRO_NAME" 10 60