#!/bin/bash
# install-password-manager-universal.sh

echo "=== Instalador Universal Password Policy Manager ==="

# Detectar distribución
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    DISTRO=$ID
else
    echo "Error: No se pudo detectar la distribución"
    exit 1
fi

# Instalar dependencias según distro
case $DISTRO in
    manjaro|arch)
        echo "Instalando para Arch/Manjaro..."
        pacman -Sy --noconfirm newt
        ;;
    debian|devuan|canaima|ubuntu|lubuntu|xubuntu|kubuntu|edubuntu|mx-linux|linuxmint)
        echo "Instalando para Debian/Ubuntu y derivados..."
        apt-get update && apt-get install -y whiptail
        ;;
    fedora|centos|rhel)
        echo "Instalando para Fedora/RHEL..."
        yum install -y newt
        ;;
    opensuse|suse)
        echo "Instalando para openSUSE..."
        zypper install -y newt
        ;;
    *)
        echo "Distribución no soportada: $DISTRO"
        echo "Instale manualmente: whiptail/libnewt/newt package"
        exit 1
        ;;
esac

# Copiar script
cp password-policy-manager-universal.sh /usr/local/bin/password-policy-manager
chmod 755 /usr/local/bin/password-policy-manager

echo "Instalación completada para $DISTRO!"
echo "Ejecute: sudo password-policy-manager"
