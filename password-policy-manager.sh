#!/bin/bash

# Password Policy Manager for Manjaro
# TUI interface using Whiptail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
LOG_FILE="/var/log/password-policy.log"
BACKUP_DIR="/etc/security/backup"
CONFIG_FILE="/etc/security/password-policy.conf"

# Verificar si es root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        whiptail --title "Error de Permisos" --msgbox "Este script requiere privilegios de root. Ejecuta con sudo." 8 60
        exit 1
    fi
}

# Crear directorio de backup
create_backup() {
    mkdir -p "$BACKUP_DIR"
    cp /etc/login.defs "$BACKUP_DIR/login.defs.backup.$(date +%Y%m%d_%H%M%S)"
}

# Log de actividades
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
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

# Menú principal
main_menu() {
    while true; do
        local choice=$(whiptail --title "Gestor de Políticas de Contraseñas" --menu \
        "Seleccione una opción:" 18 60 10 \
        "1" "Ver configuración actual" \
        "2" "Configurar política por defecto" \
        "3" "Configurar usuario específico" \
        "4" "Política avanzada" \
        "5" "Ver estado de usuarios" \
        "6" "Aplicar a todos los usuarios" \
        "7" "Backup de configuración" \
        "8" "Restaurar configuración" \
        "9" "Ver log de actividades" \
        "0" "Salir" 3>&1 1>&2 2>&3)
        
        case $choice in
            1) show_current_config ;;
            2) set_default_policy ;;
            3) set_user_policy ;;
            4) set_advanced_policy ;;
            5) check_user_status ;;
            6) apply_to_all_users ;;
            7) create_backup 
               whiptail --title "Backup" --msgbox "Backup creado exitosamente en $BACKUP_DIR" 8 50 ;;
            8) restore_backup ;;
            9) show_log ;;
            0) break ;;
            *) break ;;
        esac
    done
}

# Restaurar backup (función adicional)
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

# Inicialización
init() {
    check_root
    mkdir -p "$BACKUP_DIR"
    touch "$LOG_FILE"
    
    # Crear configuración inicial si no existe
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << EOF
# Configuración de Políticas de Contraseñas
# Archivo de configuración para password-policy-manager

DEFAULT_MAX_DAYS=90
DEFAULT_MIN_DAYS=1
DEFAULT_WARN_DAYS=7
BACKUP_ENABLED=1
LOG_ENABLED=1
EOF
    fi
}

# Mensaje de bienvenida
welcome() {
    whiptail --title "Bienvenido" --msgbox \
    "Gestor Profesional de Políticas de Contraseñas\n\n\
    Este tool permite gestionar el vencimiento de contraseñas\n\
    en sistema Manjaro Linux mediante interfaz TUI.\n\n\
    Características:\n\
    • Configuración global y por usuario\n\
    • Políticas avanzadas\n\
    • Backup y restauración\n\
    • Log de actividades" 16 60
}

# Main
init
welcome
main_menu

whiptail --title "Salida" --msgbox "¡Hasta luego! Gestor de contraseñas finalizado." 8 50