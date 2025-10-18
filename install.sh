#!/bin/bash

# ══════════════════════════════════════════════════════════
# VPS MÁSTER - Sistema Instalación Modular Pro
# Creado por: SINNOMBRE22
# Fecha: 2025-10-18 09:21:53 UTC
# Versión: 2.1 OPTIMIZADO
# ══════════════════════════════════════════════════════════

# 📁 VARIABLES GLOBALES
readonly ADM_PATH="/etc/master-vps"
readonly REPO_URL="https://raw.githubusercontent.com/SINNOMBRE22/master-vps/master"
readonly COLOR_CYAN="\033[1;36m"
readonly COLOR_YELLOW="\033[1;33m"
readonly COLOR_RED="\033[1;31m"
readonly COLOR_GREEN="\033[1;32m"
readonly COLOR_RESET="\033[0m"
readonly BOX_WIDTH=60

# ══════════════════════════════════════════════════════════
# 🎨 FUNCIONES DE ESTILOS
# ══════════════════════════════════════════════════════════

print_header(){
  local title="$1"
  echo -e "\n${COLOR_CYAN}$(printf '═%.0s' {1..60})${COLOR_RESET}"
  printf "${COLOR_CYAN}%-60s${COLOR_RESET}\n" "  ⇱ $title ⇲" | head -c 60
  echo ""
  echo -e "${COLOR_CYAN}$(printf '═%.0s' {1..60})${COLOR_RESET}\n"
}

print_line(){
  echo -e "${COLOR_CYAN}$(printf '═%.0s' {1..60})${COLOR_RESET}"
}

print_message(){
  local msg="$1"
  local color="$2"
  printf "${color}%-60s${COLOR_RESET}\n" "  $msg"
}

# ══════════════════════════════════════════════════════════
# 🔐 VALIDACIÓN
# ══════════════════════════════════════════════════════════

verify_root(){
  if [[ ! $(id -u) = 0 ]]; then
    clear
    print_header "ERROR DE EJECUCIÓN"
    print_message "DEBE EJECUTAR COMO ROOT" "$COLOR_RED"
    print_message "" "$COLOR_RESET"
    print_message "Intenta:" "$COLOR_YELLOW"
    print_message "sudo bash install.sh" "$COLOR_YELLOW"
    print_line
    echo ""
    exit 1
  fi
}

# ══════════════════════════════════════════════════════════
# ⏳ ANIMACIÓN UNIFICADA
# ══════════════════════════════════════════════════════════

install_with_progress(){
  local title="$1"
  local command="$2"
  
  # Iniciar la animación
  echo -n "$title ....... "
  
  # Ejecutar el comando
  eval "$command" &> /dev/null
  
  # Animación de "instalación"
  echo -e "${COLOR_GREEN}Instalado${COLOR_RESET}"
}

# ══════════════════════════════════════════════════════════
# 📦 INSTALAR DEPENDENCIAS DEL SISTEMA
# ══════════════════════════════════════════════════════════

install_dependencies(){
  # ARRAY DE DEPENDENCIAS
  local deps=(
    "git" "wget" "curl" "python3" "python3-pip"
    "build-essential" "openssl" "screen" "cron"
    "iptables" "apache2" "ufw" "nano" "net-tools"
    "lsof" "zip" "unzip" "figlet" "bc" "gawk"
    "grep" "at" "mlocate" "locales" "jq"
  )
  
  # Actualizar caché primero
  install_with_progress "Actualizando lista de paquetes" "apt-get update"
  
  # Instalar todas las dependencias juntas
  local deps_string="${deps[@]}"
  install_with_progress "Instalando dependencias del sistema" "apt-get install -y $deps_string"
}

# ══════════════════════════════════════════════════════════
# 📥 DESCARGAR MÓDULOS
# ══════════════════════════════════════════════════════════

download_modules(){
  cd "${ADM_PATH}"
  
  if [[ -f $HOME/lista ]]; then
    install_with_progress "Instalando script" "wget -i $HOME/lista -o /dev/null 2>&1"
    chmod +x ./* 2>/dev/null
  fi
}

# ══════════════════════════════════════════════════════════
# ✅ PANTALLAS DE ÉXITO Y ERROR
# ══════════════════════════════════════════════════════════

error_fun(){
  clear
  print_header "⚠️ ERROR DE INSTALACIÓN"
  print_message "Error en apt-get" "$COLOR_RED"
  print_message "" "$COLOR_RESET"
  print_message "Ejecute los siguientes comandos:" "$COLOR_YELLOW"
  print_message "dpkg --configure -a" "$COLOR_CYAN"
  print_message "" "$COLOR_RESET"
  print_message "Verifique su archivo sources.list" "$COLOR_YELLOW"
  print_line
  echo ""
  exit 1
}

success_fun(){
  clear
  print_header "✅ INSTALACIÓN COMPLETADA"
  echo ""
  print_message "¡BIENVENIDO A VPS MÁSTER!" "$COLOR_GREEN"
  print_message "" "$COLOR_RESET"
  print_message "✓ Instalación completada exitosamente" "$COLOR_GREEN"
  print_message "" "$COLOR_RESET"
  print_message "Comandos disponibles:" "$COLOR_YELLOW"
  print_message "  • menu" "$COLOR_CYAN"
  print_message "  • vps" "$COLOR_CYAN"
  print_message "" "$COLOR_RESET"
  print_message "Ruta de instalación: $ADM_PATH" "$COLOR_YELLOW"
  print_message "2025-10-18 09:21:53 (UTC)" "$COLOR_YELLOW"
  print_line
  echo ""
}

# ══════════════════════════════════════════════════════════
# 🎯 FLUJO PRINCIPAL
# ══════════════════════════════════════════════════════════

verify_root
trap "rm -f $0 &>/dev/null; exit" INT TERM EXIT
rm $(pwd)/$0 &>/dev/null

cd $HOME

# Preparación inicial
locale-gen en_US.UTF-8 > /dev/null 2>&1
update-locale LANG=en_US.UTF-8 > /dev/null 2>&1

clear

# PANTALLA DE BIENVENIDA
print_header "VPS MÁSTER v2.1"
print_message "Creado por: SINNOMBRE22" "$COLOR_YELLOW"
print_line
sleep 2

clear

# SELECCIONAR IDIOMA
print_header "SELECCIONAR IDIOMA"
print_message "[1] - PT-BR 🇧🇷" "$COLOR_GREEN"
print_message "[2] - EN 🇺🇸" "$COLOR_GREEN"
print_message "[3] - ES 🇪🇸" "$COLOR_GREEN"
print_message "[4] - FR 🇫🇷" "$COLOR_GREEN"
print_message "" "$COLOR_RESET"
echo -ne "${COLOR_YELLOW}  Selecciona tu opción [1-4]: ${COLOR_RESET}"
read lang

case $lang in
  1) id="pt" ;;
  2) id="en" ;;
  3) id="es" ;;
  4) id="fr" ;;
  *) id="es" ;;
esac

clear

# PANEL DE INSTALACIÓN
print_header "INSTALANDO VPS MÁSTER"

# Descargar lista de módulos
install_with_progress "Descargando lista de módulos" "wget -q -O $HOME/lista ${REPO_URL}/lista"

if [[ $? -ne 0 ]]; then
  echo -e "${COLOR_RED}Error al descargar lista${COLOR_RESET}"
  error_fun
fi

# Inicializar directorios
init_dirs

# Configurar repositorios
setup_repos

# PASO 1: Actualizar sistema
install_with_progress "Actualizando repositorios" "apt-get update -y"
install_with_progress "Actualizando paquetes del sistema" "apt-get upgrade -y"

# PASO 2: Instalar DEPENDENCIAS
install_dependencies

# PASO 3: Descargar MÓDULOS
print_message "" "$COLOR_RESET"
download_modules

# PASO 4: Configuraciones
setup_apache
run_installer
function_verify

# PASO 5: Limpiar
[[ -e $HOME/lista ]] && rm $HOME/lista
[[ -e $HOME/fim ]] && rm $HOME/fim

cp -f $0 "${ADM_PATH}/install.sh" 2>/dev/null

# PANTALLA DE ÉXITO
success_fun

exit 0
