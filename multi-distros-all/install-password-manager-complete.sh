#!/bin/bash
# install-password-manager-complete.sh

echo "=== Instalador Universal - Soporte Mandriva/Mageia ==="

# Detectar distribución completa
detect_distro

echo "Detectado: $DISTRO_NAME $DISTRO_VERSION"
echo "Gestor de paquetes: $PKG_MANAGER"

# Instalar dependencias según distro
case $DISTRO in
    mandriva|mandrake)
        echo "Instalando para Mandriva/Mandrake..."
        if command -v urpmi &> /dev/null; then
            urpmi --auto libnewt
        else
            echo "ERROR: urpmi no encontrado"
            exit 1
        fi
        ;;
    mageia)
        echo "Instalando para Mageia..."
        if command -v dnf &> /dev/null; then
            dnf install -y libnewt
        elif command -v urpmi &> /dev/null; then
            urpmi --auto libnewt
        else
            echo "ERROR: No se encontró gestor de paquetes"
            exit 1
        fi
        ;;
    openmandriva)
        echo "Instalando para OpenMandriva..."
        dnf install -y libnewt
        ;;
    fedora|centos|rhel|scientific)
        echo "Instalando para Fedora/RHEL/CentOS..."
        if command -v dnf &> /dev/null; then
            dnf install -y newt
        else
            yum install -y newt
        fi
        ;;
    debian|devuan|canaima|trisquel|ubuntu|linuxmint)
        echo "Instalando para Debian/Ubuntu..."
        apt-get update && apt-get install -y whiptail
        ;;
    opensuse|suse)
        echo "Instalando para openSUSE..."
        zypper install -y newt
        ;;
    manjaro|arch)
        echo "Instalando para Arch/Manjaro..."
        pacman -Sy --noconfirm libnewt
        ;;
    *)
        echo "Distribución no soportada automáticamente: $DISTRO"
        echo "Instale manualmente el paquete: libnewt o newt"
        echo "Luego copie el script manualmente"
        exit 1
        ;;
esac

# Copiar script principal
cp password-policy-manager-complete.sh /usr/local/bin/password-policy-manager
chmod 755 /usr/local/bin/password-policy-manager

# Crear alias
echo "alias password-manager='sudo password-policy-manager'" >> /etc/bash.bashrc

echo "Instalación completada para $DISTRO_NAME!"
echo "Ejecute: sudo password-policy-manager"
