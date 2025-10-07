#!/bin/bash
# install-password-manager-universal.sh

echo "=== Instalador Universal Password Policy Manager ==="

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo "Error: Este instalador requiere privilegios de root."
    echo "Ejecute: sudo $0"
    exit 1
fi

# Verificar que los scripts principales existen
if [[ ! -f "password-policy-manager.sh" ]]; then
    echo "Error: No se encuentra password-policy-manager.sh"
    echo "Asegúrese de ejecutar el instalador desde el directorio correcto"
    exit 1
fi

if [[ ! -f "password-policy-manager-all.sh" ]]; then
    echo "Error: No se encuentra password-policy-manager-all.sh"
    echo "Asegúrese de ejecutar el directorio con ambos scripts principales"
    exit 1
fi

# Detectar distribución
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    DISTRO=$ID
else
    echo "Error: No se pudo detectar la distribución"
    exit 1
fi

# Instalar dependencias faltantes
install_dependencies() {
    case $DISTRO in
        manjaro|arch|garuda|endeavouros)
            echo "Instalando dependencias para Arch-based..."
            pacman -Sy --noconfirm libnewt dialog
            ;;
        debian|ubuntu|linuxmint|devuan|kali)
            echo "Instalando dependencias para Debian-based..."
            apt-get update && apt-get install -y whiptail dialog
            ;;
        fedora|centos|rhel|almalinux|rocky)
            echo "Instalando dependencias para Red Hat-based..."
            yum install -y newt dialog
            ;;
        opensuse|suse|sles)
            echo "Instalando dependencias para openSUSE..."
            zypper install -y newt dialog
            ;;
        openmandriva|mageia)
            echo "Instalando dependencias para Mandriva-based..."
            # OpenMandriva usa dnf, Mageia usa urpmi
            if command -v dnf &> /dev/null; then
                dnf install -y newt dialog
            elif command -v urpmi &> /dev/null; then
                urpmi newt dialog
            else
                echo "Error: No se pudo encontrar gestor de paquetes para Mandriva-based"
                return 1
            fi
            ;;
        mandriva|mandrake)
            echo "Instalando dependencias para Mandriva/Mandrake legacy..."
            # Versiones antiguas usan urpmi
            if command -v urpmi &> /dev/null; then
                urpmi newt dialog
            elif command -v rpm &> /dev/null; then
                echo "Advertencia: urpmi no disponible, intentando con rpm manual..."
                # Instalación manual desde medios locales
                mount_local_media
                install_from_local_media "newt" "dialog"
            else
                echo "Error: No se puede instalar en Mandriva/Mandrake legacy"
                return 1
            fi
            ;;
        slackware)
            echo "Instalando dependencias para Slackware..."
            # Slackware usa pkgtools (installpkg)
            if command -v slackpkg &> /dev/null; then
                slackpkg update
                slackpkg install newt dialog
            elif command -v installpkg &> /dev/null; then
                echo "Advertencia: slackpkg no disponible, necesaria instalación manual"
                echo "Descargue newt y dialog desde: http://www.slackware.com/packages/"
                return 1
            else
                echo "Error: No se puede determinar el gestor de paquetes de Slackware"
                return 1
            fi
            ;;
        gentoo)
            echo "Instalando dependencias para Gentoo..."
            emerge --ask n dev-libs/newt app-misc/dialog
            ;;
        void)
            echo "Instalando dependencias para Void Linux..."
            xbps-install -S newt dialog
            ;;
        alpine)
            echo "Instalando dependencias para Alpine Linux..."
            apk update && apk add newt dialog
            ;;
        *)
            echo "Distribución no reconocida: $DISTRO"
            echo "Intentando métodos genéricos..."
            install_dependencies_generic
            ;;
    esac
}

# Método genérico para distribuciones no reconocidas
install_dependencies_generic() {
    local packages_missing=()
    
    # Verificar qué comandos faltan
    if ! command -v whiptail &> /dev/null; then
        packages_missing+=("whiptail")
    fi
    if ! command -v dialog &> /dev/null; then
        packages_missing+=("dialog")
    fi
    
    if [[ ${#packages_missing[@]} -eq 0 ]]; then
        echo "✓ Todas las dependencias están instaladas"
        return 0
    fi
    
    echo "Dependencias faltantes: ${packages_missing[*]}"
    
    # Intentar diferentes gestores de paquetes
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y "${packages_missing[@]}"
    elif command -v yum &> /dev/null; then
        yum install -y "${packages_missing[@]}"
    elif command -v dnf &> /dev/null; then
        dnf install -y "${packages_missing[@]}"
    elif command -v zypper &> /dev/null; then
        zypper install -y "${packages_missing[@]}"
    elif command -v pacman &> /dev/null; then
        pacman -Sy --noconfirm "${packages_missing[@]}"
    elif command -v urpmi &> /dev/null; then
        urpmi "${packages_missing[@]}"
    else
        echo "Error: No se pudo encontrar un gestor de paquetes compatible"
        echo "Instale manualmente: ${packages_missing[*]}"
        return 1
    fi
}

# Función para montar medios locales (CD/DVD/USB) en distribuciones antiguas
mount_local_media() {
    local media_paths=(
        "/mnt/cdrom"
        "/mnt/cdrom0"
        "/media/cdrom"
        "/media/cdrom0"
        "/mnt/dvd"
        "/media/dvd"
        "/mnt/usb"
        "/media/usb"
    )
    
    for path in "${media_paths[@]}"; do
        if [[ -d "$path" ]] && mountpoint -q "$path"; then
            echo "Medio local montado en: $path"
            LOCAL_MEDIA_PATH="$path"
            return 0
        fi
    done
    
    # Intentar montar CD/DVD
    if [[ -e /dev/cdrom ]]; then
        mkdir -p /mnt/cdrom
        if mount /dev/cdrom /mnt/cdrom 2>/dev/null; then
            echo "CD/DVD montado en /mnt/cdrom"
            LOCAL_MEDIA_PATH="/mnt/cdrom"
            return 0
        fi
    fi
    
    echo "Advertencia: No se pudo encontrar medio local montado"
    return 1
}

# Instalar desde medios locales (para distribuciones antiguas sin internet)
install_from_local_media() {
    local media_path="$LOCAL_MEDIA_PATH"
    if [[ -z "$media_path" ]] || [[ ! -d "$media_path" ]]; then
        echo "Error: Ruta de medios locales no disponible"
        return 1
    fi
    
    for pkg in "$@"; do
        local pkg_pattern=$(find "$media_path" -name "*${pkg}*.rpm" -o -name "*${pkg}*.deb" 2>/dev/null | head -1)
        if [[ -n "$pkg_pattern" ]]; then
            echo "Instalando $pkg desde: $pkg_pattern"
            if [[ $pkg_pattern == *.rpm ]]; then
                rpm -ivh "$pkg_pattern" || rpm -Uvh "$pkg_pattern"
            elif [[ $pkg_pattern == *.deb ]]; then
                dpkg -i "$pkg_pattern"
            fi
        else
            echo "Paquete $pkg no encontrado en medios locales"
        fi
    done
}

# Función mejorada de verificación de compatibilidad
check_compatibility() {
    local missing_tools=()
    
    # Herramientas críticas
    if ! command -v chage &> /dev/null; then
        missing_tools+=("chage")
    fi
    
    if ! command -v passwd &> /dev/null; then
        missing_tools+=("passwd")
    fi
    
    # Herramientas de interfaz (al menos una debe estar disponible)
    local has_interface=false
    if command -v whiptail &> /dev/null; then
        has_interface=true
    elif command -v dialog &> /dev/null; then
        has_interface=true
    else
        missing_tools+=("whiptail o dialog")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "Herramientas faltantes: ${missing_tools[*]}"
        return 1
    fi
    
    return 0
}

# Verificar compatibilidad antes de instalar
echo "Verificando compatibilidad del sistema..."
if ! check_compatibility; then
    echo "Instalando dependencias necesarias..."
    install_dependencies
fi

# Crear directorios necesarios
echo "Creando directorios del sistema..."
mkdir -p /usr/local/bin
mkdir -p /usr/local/share/password-manager/locales
mkdir -p /var/log
mkdir -p /etc/security/backup

# Copiar script principal
echo "Instalando scripts principales..."
cp password-policy-manager.sh /usr/local/bin/password-policy-manager
cp password-policy-manager-all.sh /usr/local/bin/password-policy-manager-all
chmod 755 /usr/local/bin/password-policy-manager
chmod 755 /usr/local/bin/password-policy-manager-all

# Copiar todos los archivos de localización
echo "Instalando archivos de idiomas..."
if [[ -d "locales" ]]; then
    cp -r locales/* /usr/local/share/password-manager/locales/
    echo "✓ Idiomas instalados correctamente"
else
    echo "Advertencia: No se encontró el directorio 'locales'"
    echo "Los idiomas no estarán disponibles hasta que copie los archivos de traducción"
fi

echo ""
echo "=== INSTALACIÓN COMPLETADA ==="
echo "Distribución: $DISTRO"
echo ""
echo "Idiomas disponibles: es_ES, en_US, fr_FR, de_DE, it_IT, pt_BR, pt_PT, zh_CN, ja_JP, ru_RU, uk_UA, be_BY, pl_PL, cs_CZ, hu_HU, ro_RO, vi_VN, th_TH, tr_TR, el_GR, sr_RS, hr_HR, bs_BA, sq_AL, sl_SI, mk_MK, nb_NO, nn_NO, no_RIK, no_HOG, no_RUNE, sv_SE, sv_SE_RUNE, is_IS, is_IS_RUNE, fi_FI, af_ZA, nl_NL, la_VA, it_AR, it_US, it_VE"
echo ""
echo "COMANDOS DISPONIBLES:"
echo "  sudo password-policy-manager      (Versión simple: para distribuciones modernas)"
echo "  sudo password-policy-manager-all  (Versión extendida: para distribuciones modernas y antiguas)"
echo ""
echo "CONFIGURACIÓN DE IDIOMA:"
echo "  Para cambiar idioma, edite la variable CURRENT_LANG en:"
echo "  /usr/local/bin/password-policy-manager"
echo "  /usr/local/bin/password-policy-manager-all"
echo ""
echo "ARCHIVOS DE LOG:"
echo "  /var/log/password-policy.log"
echo ""
echo "¡Instalación finalizada exitosamente!"