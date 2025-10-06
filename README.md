# 🔐 Gestor Interactivo de Vencimiento de Contraseñas

**Una herramienta TUI profesional para gestionar políticas de expiración de contraseñas en sistemas Linux**

## 📖 Definición

El **Gestor Interactivo de Vencimiento de Contraseñas** es una aplicación de terminal (TUI) desarrollada en Bash que permite administrar de manera intuitiva y segura las políticas de expiración de contraseñas en sistemas Linux. Utiliza `whiptail` para proporcionar una interfaz amigable y profesional.

## 🚀 Características Principales

### 🔧 Funcionalidades
- ✅ **Gestión Global**: Configuración de políticas por defecto para nuevos usuarios
- ✅ **Gestión por Usuario**: Configuración individual para usuarios existentes
- ✅ **Políticas Avanzadas**: Configuración completa (máximo, mínimo, días de aviso)
- ✅ **Monitorización en Tiempo Real**: Estado actual de todos los usuarios
- ✅ **Sistema de Backup/Restore**: Respaldo y recuperación de configuraciones
- ✅ **Log de Actividades**: Registro completo de todas las operaciones
- ✅ **Soporte Multi-Distribución**: Compatible con la mayoría de distribuciones Linux
- ✅ ⚠️ **Solo está disponible en español**

### 🛡️ Seguridad
- 🔒 Validación de entrada de datos
- 🔒 Confirmación para acciones críticas
- 🔒 Logging de todas las operaciones
- 🔒 Sistema de backup automático
- 🔒 Verificación de permisos de root

## 📦 Distribuciones Soportadas

### ✅ Compatibilidad Total (Se encuentra en el directorio: multi-distros)
- **Arch Linux** y derivados (Manjaro, Garuda, EndeavourOS, etc)
- **Debian** y derivados (Ubuntu, Canaima, Linux Mint, Devuan, MX Linux)
- **Fedora** y derivados (CentOS, RHEL, Scientific Linux)
- **openSUSE** y derivados
- **Mageia** y derivados (OpenMandriva)

### ⚠️ Compatibilidad Parcial (Se encuentra en el directorio: multi-distros-all)
- Distribuciones basadas en Mandriva/Mandrake (soporte básico)
- Sistemas antiguos con gestor urpmi

## 📥 Instalación

### Método Rápido (Recomendado)

```bash
# Descargar el script
git clone https://github.com/cesarmarcanove/passwordman-linux.git
cd passwordman-linux
```

### Método Manual

```
# Ejecutar instalador
Hacer ejecutable script instalador: sudo chmod a+x install-password-manager.sh
sudo ./install-password-manager.sh

# Hacer ejecutable el script
chmod a+x password-policy-manager.sh

# Mover a directorio del sistema
sudo cp password-policy-manager.sh /usr/local/bin/password-policy-manager
sudo chmod 755 /usr/local/bin/password-policy-manager

# Crear alias (opcional)
echo "alias password-manager='sudo password-policy-manager'" >> ~/.bashrc
source ~/.bashrc

# Ejecutar Aplicativo
sudo ./password-policy-manager.sh

```

### Directorio: multi-distros-all 
  >  Contiene soportes para antiguas distribuciones basadas de Madriva, Mandrake Linux, Mageia, OpenMadriva

  >  La mayoria se instalan en CD o DVD correspondientes segun la distribución antigua, ten en cuenta que en internet ya no estan disponibles y ya estan deprecados (obsoletos) y algunos lo trae para bajarlo la ISO desde la pagina web de **Internet Archive**, luego quemarlo en discos CD o DVD virgenes o tambien flashear **datapad (pendrive USB, memorias micro disquetes MicroSD)** con Balena Etcher, Rufus, comando dd (linux y unix).

  >  En el Caso de OpenMandriva y Mageia, lo bajan desde la pagina web y luego quemarlo en discos CD o DVD virgenes o tambien flashear **datapad (pendrive USB, memorias micro disquetes MicroSD)** con Balena Etcher, Rufus, comando dd (linux y unix).
  

### Directorio: multi-distros
  >  Contiene soportes para todas las distribuciones modernas de linux basados en: Debian, Fedora, Red Gat, Arch, Gentoo

  >  La mayoría de las distribuciones modernas, se descargan desde la pagina web oficial de la distribucion correspondiente y luego quemarlo en discos CD o DVD virgenes o tambien flashear **datapad (pendrive USB, memorias micro disquetes MicroSD)** con Balena Etcher, Rufus, comando dd (linux y unix).
  


