#!/bin/bash

# ==============================================================
# VPS MÁSTER - Sistema Instalación Modular Pro
# Creado por: SINNOMBRE22
# Fecha: 2025-10-18 09:58:36 UTC
# Versión: 2.3 OPTIMIZADO
# Ancho fijo visual: 62 columnas
# ==============================================================

# Variables globales
readonly ADM_PATH="/etc/master-vps"
readonly REPO_URL="https://raw.githubusercontent.com"\
"/SINNOMBRE22/master-vps/master"
readonly COLOR_CYAN="\033[1;36m"
readonly COLOR_YELLOW="\033[1;33m"
readonly COLOR_RED="\033[1;31m"
readonly COLOR_GREEN="\033[1;32m"
readonly COLOR_MAGENTA="\033[1;35m"
readonly COLOR_RESET="\033[0m"
readonly BOX_WIDTH=62

# =================== Estilos y Banners ========================

line_of(){
  # Uso: line_of "═" 62
  local ch="$1"; local n="$2"; local i
  for ((i=0;i<n;i++)); do printf "%s" "$ch"; done
}

print_center_title(){
  # Título centrado entre barras de '═' (ancho 62)
  local title="$1"
  local deco="⇱ ${title} ⇲"
  local w=$BOX_WIDTH
  local len=${#deco}
  (( len > w )) && deco="${deco:0:w}"
  local pad=$(( (w - len) / 2 ))
  local rest=$(( w - pad - len ))
  echo -ne "${COLOR_CYAN}"; line_of "═" "$pad"
  echo -ne "${COLOR_MAGENTA}${deco}${COLOR_CYAN}"
  line_of "═" "$rest"; echo -e "${COLOR_RESET}"
}

print_header(){
  local title="$1"
  echo -ne "${COLOR_CYAN}"; line_of "═" "$BOX_WIDTH"
  echo -e "${COLOR_RESET}"
  print_center_title "$title"
  echo -ne "${COLOR_CYAN}"; line_of "═" "$BOX_WIDTH"
  echo -e "${COLOR_RESET}\n"
}

print_line(){
  echo -ne "${COLOR_CYAN}"; line_of "═" "$BOX_WIDTH"
  echo -e "${COLOR_RESET}"
}

print_message(){
  # Imprime una línea con margén izquierdo y recorte a 60
  local msg="$1"; local color="$2"
  local text="  ${msg}"
  text="${text:0:60}"
  printf "${color}%-60s${COLOR_RESET}\n" "$text"
}

# ==================== Validaciones ============================

verify_root(){
  if [[ "$(id -u)" -ne 0 ]]; then
    clear
    print_header "ERROR DE EJECUCIÓN"
    print_message "DEBE EJECUTAR COMO ROOT" "$COLOR_RED"
    print_message "" "$COLOR_RESET"
    print_message "Intente:" "$COLOR_YELLOW"
    print_message "sudo bash install.sh" "$COLOR_YELLOW"
    print_line; echo ""
    exit 1
  fi
}

# ============== Utilidades de instalación =====================

install_with_progress(){
  # Muestra "Tarea ....... ✓/✗"
  local title="$1"; local command="$2"
  local dots=" ....... "
  local label="${title}${dots}"
  label="${label:0:50}"
  printf "  %-50s" "$label"
  bash -c "$command" &>/dev/null
  if [[ $? -eq 0 ]]; then
    echo -e " ${COLOR_GREEN}✓${COLOR_RESET}"
  else
    echo -e " ${COLOR_RED}✗${COLOR_RESET}"
  fi
}

# ============ Preparación de entorno y rutas ==================

init_dirs(){
  [[ -d "${ADM_PATH}" ]] && rm -rf "${ADM_PATH}"
  mkdir -p "${ADM_PATH}"
  cd "${ADM_PATH}" || exit 1
  : > index.html
  echo "cd ${ADM_PATH} && bash ./menu" > /bin/menu
  echo "cd ${ADM_PATH} && bash ./menu" > /bin/vps
  chmod +x /bin/menu /bin/vps
}

# ================== Dependencias del sistema ==================

install_dependencies(){
  # Incluye 'python-is-python3' para disponer de 'python'
  local deps=(
    git wget curl python3 python3-pip python-is-python3
    build-essential openssl screen cron iptables apache2 ufw
    nano net-tools lsof zip unzip figlet bc gawk grep at
    mlocate locales jq
  )
  print_message "Preparando instalación..." "$COLOR_YELLOW"
  install_with_progress "Actualizando lista" "apt-get update -y"
  install_with_progress "Actualizando paquetes" "apt-get upgrade -y"
  print_message "" "$COLOR_RESET"
  print_message "Instalando dependencias..." "$COLOR_YELLOW"
  install_with_progress "Instalando paquetes" \
    "apt-get install -y ${deps[*]}"
  print_message "" "$COLOR_RESET"
}

# =================== Descarga de Módulos ======================

download_modules(){
  cd "${ADM_PATH}" || return
  if [[ -f "$HOME/lista" ]]; then
    install_with_progress "Descargando módulos" \
      "wget -i $HOME/lista -o /dev/null 2>&1"
    chmod +x ./* 2>/dev/null
  fi
}

# =================== Configuración Apache =====================

setup_apache(){
  if [[ -f /etc/apache2/ports.conf ]]; then
    install_with_progress "Configurando Apache2" \
      "sed -i 's/^Listen 80$/Listen 81/' \
       /etc/apache2/ports.conf"
    install_with_progress "Reiniciando Apache2" \
      "service apache2 restart"
  else
    print_message "Apache2 no está configurado aún" "$COLOR_YELLOW"
  fi
}

# ===================== Ejecutor del core ======================

run_installer(){
  # Ejecuta módulo principal si existe
  if [[ -x "${ADM_PATH}/cabecalho" ]]; then
    install_with_progress "Ejecutando instalador" \
      "bash ${ADM_PATH}/cabecalho --instalar"
  elif [[ -f "${ADM_PATH}/cabecalho" ]]; then
    install_with_progress "Ejecutando instalador" \
      "bash ${ADM_PATH}/cabecalho --instalar"
  else
    print_message "Módulo 'cabecalho' no encontrado" "$COLOR_YELLOW"
  fi
}

# ======================= Verificación =========================

function_verify(){
  # Crea /bin/verifysys con contenido 'verify'
  local phex="2f62696e2f766572696679737973"
  local path
  path=$(echo -e "$(echo "$phex" | sed 's/../\\x&/g')")
  echo "verify" > "$path" 2>/dev/null || true
}

# ================== Pantallas de estado =======================

error_fun(){
  clear
  print_header "⚠️ ERROR DE INSTALACIÓN"
  print_message "Error en apt-get" "$COLOR_RED"
  print_message "" "$COLOR_RESET"
  print_message "Ejecute:" "$COLOR_YELLOW"
  print_message "dpkg --configure -a" "$COLOR_CYAN"
  print_message "" "$COLOR_RESET"
  print_message "Verifique su sources.list" "$COLOR_YELLOW"
  print_line; echo ""
  exit 1
}

success_fun(){
  clear
  print_header "✅ INSTALACIÓN COMPLETADA"
  print_message "¡BIENVENIDO A VPS MÁSTER!" "$COLOR_GREEN"
  print_message "" "$COLOR_RESET"
  print_message "✓ Instalación completada exitosamente" \
    "$COLOR_GREEN"
  print_message "" "$COLOR_RESET"
  print_message "Comandos disponibles:" "$COLOR_YELLOW"
  print_message "• menu" "$COLOR_CYAN"
  print_message "• vps" "$COLOR_CYAN"
  print_message "" "$COLOR_RESET"
  print_message "Ruta: ${ADM_PATH}" "$COLOR_YELLOW"
  print_message "2025-10-18 09:58:36 (UTC)" "$COLOR_YELLOW"
  print_line; echo ""
}

# ======================== Flujo principal =====================

verify_root
trap "rm -f \"$0\" &>/dev/null" EXIT

cd "$HOME" || exit 1
locale-gen en_US.UTF-8 > /dev/null 2>&1
update-locale LANG=en_US.UTF-8 > /dev/null 2>&1

clear
print_header "VPS MÁSTER v2.3"
print_message "Creado por: SINNOMBRE22" "$COLOR_YELLOW"
print_line; sleep 1; clear

print_header "SELECCIONAR IDIOMA"
print_message "[1] - PT-BR 🇧🇷" "$COLOR_GREEN"
print_message "[2] - EN 🇺🇸" "$COLOR_GREEN"
print_message "[3] - ES 🇪🇸" "$COLOR_GREEN"
print_message "[4] - FR 🇫🇷" "$COLOR_GREEN"
print_message "" "$COLOR_RESET"
echo -ne "${COLOR_YELLOW}  Opción [1-4]: ${COLOR_RESET}"
read -r lang
case "$lang" in
  1) id="pt" ;; 2) id="en" ;;
  3) id="es" ;; 4) id="fr" ;;
  *) id="es" ;;
esac
clear

print_header "INSTALANDO VPS MÁSTER"

# Descargar lista de módulos
install_with_progress "Descargando lista" \
  "wget -q -O \"$HOME/lista\" \
   \"${REPO_URL}/lista\""

if [[ $? -ne 0 ]]; then
  print_message "Error al descargar la lista" "$COLOR_RED"
  error_fun
fi

# Inicialización y preparación
init_dirs
print_message "" "$COLOR_RESET"

# Dependencias del sistema
install_dependencies

# Configuraciones de servicio
setup_apache

# Descarga y ejecución de módulos
download_modules
run_installer
function_verify

# Limpieza
[[ -e "$HOME/lista" ]] && rm -f "$HOME/lista"
[[ -e "$HOME/fim"  ]] && rm -f "$HOME/fim"

# Éxito
success_fun
exit 0
