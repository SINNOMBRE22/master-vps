#!/bin/bash

# ═════════════════════════════════════════════════════════
# VPS MÁSTER - Sistema Instalación Modular Pro
# Creado por: SINNOMBRE22
# Fecha: 2025-10-18 09:53:29 UTC
# Versión: 2.2 OPTIMIZADO COMPLETO
# ═════════════════════════════════════════════════════════

# 📁 VARIABLES GLOBALES
readonly ADM_PATH="/etc/master-vps"
readonly REPO_URL="https://raw.githubusercontent.com/SINNOMBRE22/master-vps/master"
readonly COLOR_CYAN="\033[1;36m"
readonly COLOR_YELLOW="\033[1;33m"
readonly COLOR_RED="\033[1;31m"
readonly COLOR_GREEN="\033[1;32m"
readonly COLOR_MAGENTA="\033[1;35m"
readonly COLOR_RESET="\033[0m"
readonly BOX_WIDTH=60

# ═════════════════════════════════════════════════════════
# 🎨 FUNCIONES DE ESTILOS
# ═════════════════════════════════════════════════════════

print_header(){
  local title="$1"
  echo -e "\n${COLOR_CYAN}$(printf '═%.0s' {1..60})${COLOR_RESET}"
  printf "${COLOR_MAGENTA}%-60s${COLOR_RESET}\n" "  ⇱ $title ⇲"
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

# ═════════════════════════════════════════════════════════
# 🔐 VALIDACIÓN
# ═════════════════════════════════════════════════════════

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

# ═════════════════════════════════════════════════════════
# 📁 INICIALIZAR DIRECTORIOS
# ═════════════════════════════════════════════════════════

init_dirs(){
  if [[ -d "${ADM_PATH}" ]]; then
    rm -rf "${ADM_PATH}"
  fi
  mkdir -p "${ADM_PATH}"
  cd "${ADM_PATH}"
  touch index.html
  echo "cd ${ADM_PATH} && bash ./menu" > /bin/menu
  echo "cd ${ADM_PATH} && bash ./menu" > /bin/vps
  chmod +x /bin/menu /bin/vps
}

# ═════════════════════════════════════════════════════════
# 🔧 CONFIGURAR REPOSITORIOS
# ═════════════════════════════════════════════════════════

setup_repos(){
  echo "deb http://deb.debian.org/debian $(lsb_release -cs) main contrib non-free" > /etc/apt/sources.list
  echo "deb http://deb.debian.org/debian $(lsb_release -cs)-updates main contrib non-free" >> /etc/apt/sources.list
}

# ═════════════════════════════════════════════════════════
# ⏳ ANIMACIÓN UNIFICADA
# ═════════════════════════════════════════════════════════

install_with_progress(){
  local title="$1"
  local command="$2"
  
  echo -n "$title ....... "
  eval "$command" &> /dev/null
  
  if [[ $? -eq 0 ]]; then
    echo -e "${COLOR_GREEN}✓${COLOR_RESET}"
  else
    echo -e "${COLOR_RED}✗${COLOR_RESET}"
  fi
}

# ═════════════════════════════════════════════════════════
# 📦 INSTALAR DEPENDENCIAS DEL SISTEMA
# ═════════════════════════════════════════════════════════

install_dependencies(){
  local deps=(
    "git" "wget" "curl" "python3" "python3-pip"
    "build-essential" "openssl" "screen" "cron"
    "iptables" "apache2" "ufw" "nano" "net-tools"
    "lsof" "zip" "unzip" "figlet" "bc" "gawk"
    "grep" "at" "mlocate" "locales" "jq"
  )
  
  print_message "Preparando instalación..." "$COLOR_YELLOW"
  install_with_progress "Actualizando lista" "apt-get update -y"
  
  print_message "" "$COLOR_RESET"
  print_message "Instalando dependencias..." "$COLOR_YELLOW"
  
  local deps_string="${deps[@]}"
  install_with_progress "Instalando paquetes" "apt-get install -y $deps_string"
  
  print_message "" "$COLOR_RESET"
}

# ═════════════════════════════════════════════════════════
# 🔐 CONFIGURAR APACHE2
# ═════════════════════════════════════════════════════════

setup_apache(){
  install_with_progress "Configurando Apache2" \
    "sed -i 's/Listen 80/Listen 81/g' /etc/apache2/ports.conf"
  install_with_progress "Reiniciando Apache2" \
    "service apache2 restart"
}

# ═════════════════════════════════════════════════════════
# 📥 DESCARGAR Y EJECUTAR INSTALADOR
# ═════════════════════════════════════════════════════════

run_installer(){
  if [[ -f "${ADM_PATH}/cabecalho" ]]; then
    cd "${ADM_PATH}"
    bash ./cabecalho --instalar 2>/dev/null
  fi
}

# ═════════════════════════════════════════════════════════
# ✔️ VERIFICACIÓN
# ═════════════════════════════════════════════════════════

function_verify(){
  echo "verify" > /bin/verificarsys 2>/dev/null || true
}

# ═════════════════════════════════════════════════════════
# 📥 DESCARGAR MÓDULOS
# ═════════════════════════════════════════════════════════

download_modules(){
  cd "${ADM_PATH}"
  
  if [[ -f "$HOME/lista" ]]; then
    install_with_progress "Descargando módulos" \
      "wget -i $HOME/lista -o /dev/null 2>&1"
    chmod +x ./* 2>/dev/null
  fi
}

# ═════════════════════════════════════════════════════════
# ✅ PANTALLAS DE ÉXITO Y ERROR
# ═════════════════════════════════════════════════════════

error_fun(){
  clear
  print_header "⚠️ ERROR DE INSTALACIÓN"
  print_message "Error en apt-get" "$COLOR_RED"
  print_message "" "$COLOR_RESET"
  print_message "Ejecute los siguientes comandos:" "$COLOR_YELLOW"
  print_message "dpkg --configure -a" "$COLOR_CYAN"
  print_message "" "$COLOR_RESET"
  print_message "Verifique su archivo sources.list" \
    "$COLOR_YELLOW"
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
  print_message "✓ Instalación completada exitosamente" \
    "$COLOR_GREEN"
  print_message "" "$COLOR_RESET"
  print_message "Comandos disponibles:" "$COLOR_YELLOW"
  print_message "  • menu" "$COLOR_CYAN"
  print_message "  • vps" "$COLOR_CYAN"
  print_message "" "$COLOR_RESET"
  print_message "Ruta: ${ADM_PATH}" "$COLOR_YELLOW"
  print_message "2025-10-18 09:53:29 (UTC)" "$COLOR_YELLOW"
  print_line
  echo ""
}

# ═════════════════════════════════════════════════════════
# 🎯 FLUJO PRINCIPAL
# ═════════════════════════════════════════════════════════

verify_root
trap "rm -f $0 &>/dev/null; exit" INT TERM EXIT
rm $(pwd)/$0 &>/dev/null

cd $HOME

# Preparación inicial
locale-gen en_US.UTF-8 > /dev/null 2>&1
update-locale LANG=en_US.UTF-8 > /dev/null 2>&1

clear

# PANTALLA DE BIENVENIDA
print_header "VPS MÁSTER v2.2"
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
install_with_progress "Descargando módulos" \
  "wget -q -O $HOME/lista ${REPO_URL}/lista"

if [[ $? -ne 0 ]]; then
  error_fun
fi

# Inicializar directorios
init_dirs

# Configurar repositorios
setup_repos

# PASO 1: Actualizar sistema
print_message "" "$COLOR_RESET"
install_with_progress "Actualizando repositorios" \
  "apt-get update -y"
install_with_progress "Actualizando paquetes" \
  "apt-get upgrade -y"

# PASO 2: Instalar DEPENDENCIAS
print_message "" "$COLOR_RESET"
install_dependencies

# PASO 3: Configuraciones
print_message "" "$COLOR_RESET"
setup_apache

# PASO 4: Descargar MÓDULOS
print_message "" "$COLOR_RESET"
download_modules

# PASO 5: Ejecutar instalador
print_message "" "$COLOR_RESET"
run_installer
function_verify

# PASO 6: Limpiar
[[ -e $HOME/lista ]] && rm $HOME/lista
[[ -e $HOME/fim ]] && rm $HOME/fim

# PANTALLA DE ÉXITO
print_message "" "$COLOR_RESET"
success_fun

exit 0
