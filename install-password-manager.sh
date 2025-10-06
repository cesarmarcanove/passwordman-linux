#!/bin/bash

# Script de instalación para Password Policy Manager

INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/security"

echo "Instalando Password Policy Manager..."

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo "Error: Este script debe ejecutarse como root"
    exit 1
fi

# Copiar script principal
cp password-policy-manager.sh $INSTALL_DIR/password-policy-manager
chmod +x $INSTALL_DIR/password-policy-manager
chmod 755 $INSTALL_DIR/password-policy-manager

# Crear directorios de configuración
mkdir -p $CONFIG_DIR/backup
mkdir -p /var/log

# Crear archivo de log
touch /var/log/password-policy.log
chmod 644 /var/log/password-policy.log

# Crear alias para fácil acceso
echo "alias password-manager='sudo password-policy-manager'" >> /etc/bash.bashrc

# Crear acceso directo en el menú (opcional)
cat > /usr/share/applications/password-policy-manager.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Password Policy Manager
Comment=Gestor de políticas de contraseñas para Manjaro
Exec=sudo password-policy-manager
Icon=dialog-password
Terminal=true
Categories=System;Security;
Keywords=password;security;policy;
EOF

echo "Instalación completada exitosamente!"
echo ""
echo "Uso:"
echo "  password-policy-manager    # Ejecutar como root"
echo "  password-manager           # Usando alias"
echo ""
echo "El programa está disponible en el menú de aplicaciones en la categoría Sistema/Seguridad"