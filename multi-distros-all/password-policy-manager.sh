#!/bin/bash

# Password Policy Manager - Soporte Completo Mandriva/Mageia
# Incluye todas las distribuciones basadas en RPM históricas y modernas

# Detectar distribución específica
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO=$ID
        DISTRO_NAME=$NAME
        DISTRO_VERSION=$VERSION_ID
    elif [[ -f /etc/mandriva-release ]]; then
        DISTRO="mandriva"
        DISTRO_NAME="Mandriva Linux"
        DISTRO_VERSION=$(grep -o '[0-9.]*' /etc/mandriva-release | head -1)
    elif [[ -f /etc/mandrake-release ]]; then
        DISTRO="mandrake"
        DISTRO_NAME="Mandrake Linux"
        DISTRO_VERSION=$(grep -o '[0-9.]*' /etc/mandrake-release | head -1)
    elif [[ -f /etc/mageia-release ]]; then
        DISTRO="mageia"
        DISTRO_NAME="Mageia"
        DISTRO_VERSION=$(grep -o '[0-9]*' /etc/mageia-release | head -1)
    elif [[ -f /etc/redhat-release ]]; then
        if grep -qi "centos" /etc/redhat-release; then
            DISTRO="centos"
        elif grep -qi "red hat" /etc/redhat-release; then
            DISTRO="rhel"
        elif grep -qi "scientific" /etc/redhat-release; then
            DISTRO="scientific"
        else
            DISTRO="redhat"
        fi
        DISTRO_NAME=$(cat /etc/redhat-release)
        DISTRO_VERSION=$(grep -o '[0-9.]*' /etc/redhat-release | head -1)
    elif [[ -f /etc/fedora-release ]]; then
        DISTRO="fedora"
        DISTRO_NAME="Fedora Linux"
        DISTRO_VERSION=$(grep -o '[0-9]*' /etc/fedora-release | head -1)
    elif [[ -f /etc/SuSE-release ]]; then
        DISTRO="suse"
        DISTRO_NAME="SUSE Linux"
        DISTRO_VERSION=$(grep -o '[0-9.]*' /etc/SuSE-release | head -1)
    elif [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
        DISTRO_NAME="Debian GNU/Linux"
        DISTRO_VERSION=$(cat /etc/debian_version)
    else
        DISTRO="unknown"
        DISTRO_NAME="Unknown Distribution"
        DISTRO_VERSION="unknown"
    fi
    
    # Detectar gestor de paquetes
    detect_package_manager
}

# Detectar gestor de paquetes
detect_package_manager() {
    if command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
    elif command -v urpmi &> /dev/null; then
        PKG_MANAGER="urpmi"
    elif command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
    elif command -v zypper &> /dev/null; then
        PKG_MANAGER="zypper"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
    else
        PKG_MANAGER="unknown"
    fi
}

# Configuración específica para distribuciones Mandriva/Mageia
setup_mandriva_config() {
    case $DISTRO in
        mandriva|mandrake)
            LOGIN_DEFS="/etc/login.defs"
            PAM_PWQUALITY="/etc/security/pam_pwquality.conf"
            PAM_DIR="/etc/pam.d"
            CONFIG_DIR="/etc/security"
            ;;
        mageia)
            LOGIN_DEFS="/etc/login.defs"
            PAM_PWQUALITY="/etc/security/pam_pwquality.conf"
            PAM_DIR="/etc/pam.d"
            CONFIG_DIR="/etc/security"
            ;;
        *)
            # Configuración por defecto (del script anterior)
            setup_distro_config
            ;;
    esac
}

# Instalar dependencias para Mandriva/Mageia
install_mandriva_dependencies() {
    case $DISTRO in
        mandriva|mandrake)
            echo "Instalando para Mandriva/Mandrake..."
            if command -v urpmi &> /dev/null; then
                if ! command -v whiptail &> /dev/null; then
                    if [[ -n "$INSTALL_FROM_DVD" ]]; then
                        # Instalar desde DVD local
                        urpmi --auto --no-verify-rpm libnewt
                    else
                        # Intentar desde repositorios en línea
                        urpmi --auto libnewt
                    fi
                fi
            else
                echo "ERROR: No se encontró urpmi en el sistema"
                return 1
            fi
            ;;
        mageia)
            echo "Instalando para Mageia..."
            if command -v dnf &> /dev/null; then
                dnf install -y libnewt
            elif command -v urpmi &> /dev/null; then
                urpmi --auto libnewt
            else
                echo "ERROR: No se encontró gestor de paquetes en Mageia"
                return 1
            fi
            ;;
        openmandriva)
            echo "Instalando para OpenMandriva..."
            dnf install -y libnewt
            ;;
    esac
}

# Verificar compatibilidad con sistemas antiguos
check_old_system_compatibility() {
    local issues=()
    
    case $DISTRO in
        mandriva|mandrake)
            # Verificar versión específica
            local major_version=$(echo "$DISTRO_VERSION" | cut -d. -f1)
            if [[ $major_version -lt 10 ]]; then
                issues+=("Mandriva/Mandrake versión muy antigua ($DISTRO_VERSION)")
                issues+=("Puede haber problemas de compatibilidad")
            fi
            
            # Verificar si urpmi está disponible
            if ! command -v urpmi &> /dev/null; then
                issues+=("No se encontró el gestor de paquetes urpmi")
            fi
            ;;
        mageia)
            # Mageia es más moderno, menos problemas
            if [[ $DISTRO_VERSION -lt 5 ]]; then
                issues+=("Mageia versión antigua ($DISTRO_VERSION)")
            fi
            ;;
    esac
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        local issue_text="Posibles problemas detectados:\n\n"
        for issue in "${issues[@]}"; do
            issue_text+="• $issue\n"
        done
        
        whiptail --title "Advertencia de Compatibilidad" \
                 --yesno "$issue_text\n¿Continuar de todas formas?" 15 60
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi
    
    return 0
}

# Función mejorada de instalación de dependencias
enhanced_install_dependencies() {
    case $DISTRO in
        mandriva|mandrake|mageia|openmandriva)
            install_mandriva_dependencies
            ;;
        fedora|centos|rhel|scientific)
            echo "Instalando para Fedora/RHEL/CentOS..."
            if command -v dnf &> /dev/null; then
                dnf install -y newt
            else
                yum install -y newt
            fi
            ;;
        debian|devuan|canaima|lubuntu|kubuntu|xubuntu|ubuntu|trisquel|linuxmint)
            echo "Instalando para Debian/Ubuntu..."
            apt-get update && apt-get install -y whiptail
            ;;
        opensuse|suse)
            echo "Instalando para openSUSE..."
            zypper install -y newt
            ;;
        manjaro|arch)
            echo "Instalando para Arch/Manjaro..."
            pacman -Sy --noconfirm newt
            ;;
        *)
            echo "Distribución no identificada: $DISTRO"
            echo "Intente instalar manualmente el paquete: libnewt o newt"
            return 1
            ;;
    esac
}

# Configuración específica de PAM para Mandriva
setup_mandriva_pam() {
    case $DISTRO in
        mandriva|mandrake)
            whiptail --title "Configuración Mandriva" --msgbox \
            "En Mandriva/Mandrake, la configuración PAM se encuentra en:\n\n\
            • /etc/pam.d/system-auth\n\
            • /etc/security/pam_pwquality.conf\n\n\
            Las políticas se aplican mediante pam_pwquality." 12 60
            ;;
        mageia)
            whiptail --title "Configuración Mageia" --msgbox \
            "En Mageia, la configuración es similar a Fedora:\n\n\
            • /etc/pam.d/system-auth\n\
            • /etc/security/pam_pwquality.conf\n\n\
            Se utiliza pam_pwquality para validación." 12 60
            ;;
    esac
}

# Mostrar información específica de Mandriva
show_mandriva_info() {
    local info_text="Información del Sistema - $DISTRO_NAME\n\n"
    info_text+="Versión: $DISTRO_VERSION\n"
    info_text+="Gestor de paquetes: $PKG_MANAGER\n\n"
    
    case $DISTRO in
        mandriva|mandrake)
            info_text+="Características específicas:\n"
            info_text+="• Sistema: Mandriva/Mandrake Linux\n"
            info_text+="• Configuración: /etc/login.defs + PAM\n"
            info_text+="• Gestor: urpmi (RPM-based)\n"
            info_text+="• Recomendación: Verificar repositorios\n"
            ;;
        mageia)
            info_text+="Características específicas:\n"
            info_text+="• Sistema: Mageia Linux\n"
            info_text+="• Configuración: Compatible con Fedora\n"
            info_text+="• Gestor: dnf/urpmi\n"
            info_text+="• Estado: Totalmente compatible\n"
            ;;
        openmandriva)
            info_text+="Características específicas:\n"
            info_text+="• Sistema: OpenMandriva Lx\n"
            info_text+="• Configuración: Similar a Mageia\n"
            info_text+="• Gestor: dnf\n"
            info_text+="• Estado: Totalmente compatible\n"
            ;;
    esac
    
    whiptail --title "Información Mandriva/Mageia" --msgbox "$info_text" 16 70
}

# Función para configurar desde DVD local
setup_from_dvd() {
    if whiptail --title "Instalación desde DVD" --yesno \
        "¿Desea configurar la instalación desde DVD local?\n\n\
        Esto es útil para sistemas sin conexión a internet\n\
        o con repositorios en medios locales." 12 60; then
        
        INSTALL_FROM_DVD=1
        
        case $DISTRO in
            mandriva|mandrake)
                whiptail --title "Instalación Mandriva desde DVD" --msgbox \
                "Para instalar desde DVD en Mandriva/Mandrake:\n\n\
                1. Inserte el DVD de instalación\n\
                2. Monte el DVD: mount /dev/cdrom /mnt/cdrom\n\
                3. Configure los repositorios:\n\
                   urpmi.addmedia dvd /mnt/cdrom/media/main/release\n\
                4. Ejecute la instalación nuevamente" 14 60
                ;;
            mageia)
                whiptail --title "Instalación Mageia desde DVD" --msgbox \
                "Para instalar desde DVD en Mageia:\n\n\
                1. Inserte el DVD de instalación\n\
                2. Monte el DVD: mount /dev/sr0 /mnt/cdrom\n\
                3. Configure el repositorio:\n\
                   dnf config-manager --add-repo=file:///mnt/cdrom\n\
                4. Ejecute la instalación nuevamente" 14 60
                ;;
        esac
    fi
}

# Menú extendido con opciones Mandriva/Mageia
complete_main_menu() {
    while true; do
        local mandriva_options=""
        
        case $DISTRO in
            mandriva|mandrake|mageia|openmandriva)
                mandriva_options="\n\"M\" \"Información Mandriva/Mageia\"\n\"D\" \"Configurar desde DVD\""
                ;;
        esac
        
        local menu_text="Gestor de Políticas - $DISTRO_NAME $DISTRO_VERSION\nGestor: $PKG_MANAGER\n\nSeleccione:"
        
        local choice=$(whiptail --title "Gestor Completo" --menu "$menu_text" 24 75 14 \
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
        "M" "Información Mandriva/Mageia" \
        "D" "Configurar desde DVD" \
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
            M) show_mandriva_info ;;
            D) setup_from_dvd ;;
            L) show_log ;;
            0) break ;;
            *) break ;;
        esac
    done
}

# Inicialización completa
complete_init() {
    check_root
    detect_distro
    setup_mandriva_config
    
    # Mostrar información de detección
    echo "Sistema detectado: $DISTRO_NAME $DISTRO_VERSION"
    echo "Gestor de paquetes: $PKG_MANAGER"
    
    # Verificar compatibilidad para sistemas antiguos
    if [[ $DISTRO =~ ^(mandriva|mandrake|mageia) ]]; then
        if ! check_old_system_compatibility; then
            exit 1
        fi
    fi
    
    if ! check_compatibility; then
        if whiptail --title "Instalar Dependencias" --yesno \
        "¿Desea instalar las dependencias faltantes?\n\nDistro: $DISTRO_NAME\nPaquete: libnewt/newt" 12 60; then
            enhanced_install_dependencies
        else
            exit 1
        fi
    fi
    
    # Crear estructura de directorios
    mkdir -p "$BACKUP_DIR"
    touch "$LOG_FILE"
}

# Mensaje de bienvenida para sistemas Mandriva
mandriva_welcome() {
    local welcome_text="Gestor de Políticas de Contraseñas\n\n"
    welcome_text+="Bienvenido - $DISTRO_NAME $DISTRO_VERSION\n\n"
    
    case $DISTRO in
        mandriva)
            welcome_text+="Sistema Mandriva Linux detectado\n"
            welcome_text+="Soporte completo disponible\n"
            ;;
        mandrake)
            welcome_text+="Sistema Mandrake Linux detectado\n"
            welcome_text+="Soporte básico - verifique compatibilidad\n"
            ;;
        mageia)
            welcome_text+="Sistema Mageia Linux detectado\n"
            welcome_text+="Soporte completo disponible\n"
            ;;
        openmandriva)
            welcome_text+="Sistema OpenMandriva detectado\n"
            welcome_text+="Soporte completo disponible\n"
            ;;
    esac
    
    welcome_text+="\nGestor de paquetes: $PKG_MANAGER"
    
    whiptail --title "Bienvenido" --msgbox "$welcome_text" 16 60
}

# Main execution para sistemas Mandriva/Mageia
case "${1:-}" in
    "--detect-only")
        detect_distro
        echo "Distro: $DISTRO"
        echo "Name: $DISTRO_NAME"
        echo "Version: $DISTRO_VERSION"
        echo "Package Manager: $PKG_MANAGER"
        exit 0
        ;;
esac

complete_init

# Mensaje de bienvenida específico
if [[ $DISTRO =~ ^(mandriva|mandrake|mageia|openmandriva) ]]; then
    mandriva_welcome
else
    multi_distro_welcome
fi

complete_main_menu