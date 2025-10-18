#!/bin/bash

# ==============================================================
# VPS MÁSTER - Instalador similar a VPS-AGN, adaptado a rutas
# Proyecto: SINNOMBRE22/master-vps
# Fecha: 2025-10-18 10:06:49 UTC
# Versión: 3.0 ESTABLE
# Ancho visual: 62 columnas
# ==============================================================

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Rutas y constantes del proyecto
ADM_PATH="/etc/master-vps"
REPO_URL="https://raw.githubusercontent.com/SINNOMBRE22/master-vps/master"
LOG_FILE="/var/log/vps-master-install.log"
BOX_WIDTH=62
TIMEZONE_DEFAULT="UTC"

# Colores
BRAN='\033[1;37m'; RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'
BLUE='\e[34m'; MAGENTA='\e[35m'; CYAN='\033[1;36m'; RESET='\e[0m'

# --------------------------- Utilidades visuales ---------------------------

line_of(){ local ch="$1"; local n="$2"; for((i=0;i<n;i++));do printf "%s" "$ch"; done; }

print_center_bar(){
  local title="$1"; local deco="⇱ ${title} ⇲"
  local w=$BOX_WIDTH; local len=${#deco}
  (( len > w )) && deco="${deco:0:w}"
  local pad=$(( (w - len) / 2 )); local rest=$(( w - pad - len ))
  echo -ne "${CYAN}"; line_of "═" "$pad"
  echo -ne "${MAGENTA}${deco}${CYAN}"
  line_of "═" "$rest"; echo -e "${RESET}"
}

header(){
  echo -ne "${CYAN}"; line_of "═" "$BOX_WIDTH"; echo -e "${RESET}"
  print_center_bar "$1"
  echo -ne "${CYAN}"; line_of "═" "$BOX_WIDTH"; echo -e "${RESET}\n"
}

hline(){ echo -ne "${CYAN}"; line_of "═" "$BOX_WIDTH"; echo -e "${RESET}"; }

msg(){ # msg "<texto>" "<color>"
  local text="  ${1}"; text="${text:0:60}"; local color="${2:-$BRAN}"
  printf "${color}%-60s${RESET}\n" "$text"
}

# Estilo tipo VPS-AGN: barra de progreso textual
fun_bar(){
  local comando="$1"
  ( bash -c "$comando" >>"$LOG_FILE" 2>&1 ) &
  local pid=$!; echo -ne "  ${YELLOW}["
  while kill -0 "$pid" 2>/dev/null; do
    for ((i=0;i<10;i++)); do echo -ne "${RED}##"; sleep 0.15; done
    echo -ne "${YELLOW}]"; sleep 0.4; echo; tput cuu1; tput dl1
    echo -ne "  ${YELLOW}["
  done
  echo -e "  ${YELLOW}[\033[1;31m########################################\033[1;33m] - ${GREEN}100%${RESET}"
}

print_center(){
  # similar al del ejemplo (centra hasta 54 chars útiles)
  local col="${1:-}"; local text; local color="$col"
  shift || true
  text="${*}"
  [[ -z "$text" ]] && read -r text
  while IFS= read -r line; do
    local space=""; local L=$(( (54 - ${#line}) / 2 ))
    for ((i=0;i<L;i++)); do space+=' '; done
    if [[ "$color" =~ ^\\e ]]; then
      printf "%b%s%b\n" "$color" "$space$line" "$RESET"
    else
      msg "$space$line"
    fi
  done <<<"$text"
}

# ------------------------------ Auxiliares -------------------------------

ensure_log(){ : > "$LOG_FILE" || true; }

verify_root(){
  if [[ "$(id -u)" -ne 0 ]]; then
    clear; header "ERROR DE EJECUCIÓN"
    msg "Debe ejecutar como root" "$RED"
    msg "Intente: sudo bash install.sh" "$YELLOW"; hline; echo; exit 1
  fi
}

set_timezone(){
  local tz="${TIMEZONE:-$TIMEZONE_DEFAULT}"
  ln -sf "/usr/share/zoneinfo/$tz" /etc/localtime >/dev/null 2>&1 || true
}

retry(){
  # retry <intentos> <cmd...>
  local max="$1"; shift; local i
  for ((i=1;i<=max;i++)); do
    if bash -c "$*" >>"$LOG_FILE" 2>&1; then return 0; fi
    sleep 2
  done
  return 1
}

install_with_progress(){
  local title="$1"; shift; local cmd="$*"
  local dots=" ....... "; local label="${title}${dots}"
  label="${label:0:50}"; printf "  %-50s" "$label"
  if retry 3 "$cmd"; then echo -e " ${GREEN}✓${RESET}"
  else echo -e " ${RED}✗${RESET}"; return 1; fi
}

# --------------------------- Sistema / Rutas -----------------------------

init_dirs(){
  [[ -d "$ADM_PATH" ]] && rm -rf "$ADM_PATH"
  mkdir -p "$ADM_PATH"; : > "$ADM_PATH/index.html"
  echo "cd $ADM_PATH && bash ./menu" > /bin/menu
  echo "cd $ADM_PATH && bash ./menu" > /bin/vps
  chmod +x /bin/menu /bin/vps
}

detect_net(){
  # requiere net-tools; se instala temprano
  local ip iface
  ip=$(ifconfig 2>/dev/null | awk '/inet /{print $2}' | grep -v '^127\.' | head -n1)
  iface=$(ifconfig 2>/dev/null | grep -B1 "inet $ip" | head -n1 | awk '{print $1}')
  echo "$ip" > "$ADM_PATH/.ip" 2>/dev/null || true
  echo "$iface" > "$ADM_PATH/.iface" 2>/dev/null || true
}

# -------------------------- Dependencias -------------------------------

install_deps_iter(){
  # Paquetes solicitados + equivalentes modernos y TLS
  local soft=(
    ca-certificates lsb-release
    git wget curl python3 python3-pip python-is-python3
    build-essential openssl screen cron iptables apache2 ufw
    nano net-tools lsof zip unzip figlet bc gawk grep at
    mlocate locales jq
  )
  msg "Preparando instalación..." "$YELLOW"
  install_with_progress "Actualizando repositorios" "apt-get update -y" || true
  install_with_progress "Actualizando paquetes" "apt-get upgrade -y" || true
  echo
  print_center "$YELLOW" "INSTALANDO DEPENDENCIAS"
  hline
  for pkg in "${soft[@]}"; do
    local pts dots="....................."
    local gap=$((21 - ${#pkg})); pts="${dots:0:$gap}"
    printf "    \033[1;36minstalling %s\033[0m" "$pkg"
    printf "%s" "$(printf '%s' "$pts" | sed 's/ /./g')"
    if apt-get install -y "$pkg" >>"$LOG_FILE" 2>&1; then
      echo -e " ${GREEN}INSTALLED${RESET}"
    else
      echo -e " ${YELLOW}FIXING${RESET}"
      dpkg --configure -a >>"$LOG_FILE" 2>&1 || true
      apt-get -f install -y >>"$LOG_FILE" 2>&1 || true
      if apt-get install -y "$pkg" >>"$LOG_FILE" 2>&1; then
        echo -e "    ${GREEN}OK AFTER FIX${RESET}"
      else
        echo -e "    ${RED}ERROR${RESET}"
      fi
    fi
  done
  echo
  install_with_progress "Limpieza de paquetes" "apt-get autoremove -y" || true
}

# ---------------------- Descarga de módulos ----------------------------

download_lista(){
  install_with_progress "Descargando lista" \
    "wget -q -O \"$HOME/lista\" \"$REPO_URL/lista\" || curl -fsSL \"$REPO_URL/lista\" -o \"$HOME/lista\""
}

download_modules(){
  if [[ -f "$HOME/lista" ]]; then
    ( cd "$ADM_PATH" && fun_bar "wget -q -i \"$HOME/lista\"" )
    chmod +x "$ADM_PATH"/* 2>/dev/null || true
  else
    msg "No se encontró \$HOME/lista" "$YELLOW"
  fi
}

# -------------------- Configuración de Apache --------------------------

setup_apache(){
  if [[ -f /etc/apache2/ports.conf ]]; then
    install_with_progress "Configurando Apache2" \
      "awk '
        BEGIN{c=0}
        /^Listen[[:space:]]+80$/           {print \"Listen 81\"; c=1; next}
        /^Listen[[:space:]]+0.0.0.0:80$/   {print \"Listen 0.0.0.0:81\"; c=1; next}
        {print}
        END{if(c==0) print \"Listen 81\"}
      ' /etc/apache2/ports.conf > /tmp/ports.conf && mv /tmp/ports.conf /etc/apache2/ports.conf"
    install_with_progress "Reiniciando Apache2" "service apache2 restart" || true
  else
    msg "Apache2 no encontrado aún" "$YELLOW"
  fi
}

# ----------------------- Núcleo del instalador -------------------------

run_installer(){
  if [[ -f "$ADM_PATH/cabecalho" ]]; then
    fun_bar "bash \"$ADM_PATH/cabecalho\" --instalar"
  else
    msg "Módulo 'cabecalho' no encontrado" "$YELLOW"
  fi
}

function_verify(){
  # Escribe 'verify' en /bin/verifysys (ruta codificada en hex)
  local phex="2f62696e2f766572696679737973"
  local path; path=$(echo -e "$(echo "$phex" | sed 's/../\\x&/g')")
  echo "verify" > "$path" 2>/dev/null || true
}

# ----------------------- Pantallas finales -----------------------------

error_exit(){
  clear; header "⚠️ ERROR DE INSTALACIÓN"
  msg "Revise el log:" "$YELLOW"
  msg "$LOG_FILE" "$CYAN"
  msg "" "$BRAN"
  msg "Ejecute: dpkg --configure -a" "$CYAN"
  msg "y reintente la instalación." "$YELLOW"
  hline; echo; exit 1
}

success_screen(){
  clear; header "✅ INSTALACIÓN COMPLETADA"
  msg "¡BIENVENIDO A VPS MÁSTER!" "$GREEN"
  msg "" "$BRAN"
  msg "✓ Instalación completada exitosamente" "$GREEN"
  msg "" "$BRAN"
  msg "Comandos disponibles:" "$YELLOW"
  msg "• menu" "$CYAN"
  msg "• vps" "$CYAN"
  msg "" "$BRAN"
  msg "Ruta: $ADM_PATH" "$YELLOW"
  msg "$(date -u '+%Y-%m-%d %H:%M:%S') (UTC)" "$YELLOW"
  hline; echo
}

# --------------------------- Flujo principal ---------------------------

main(){
  ensure_log
  verify_root
  trap 'true' INT TERM

  clear; header "VPS MÁSTER v3.0"
  msg "Creado por: SINNOMBRE22" "$YELLOW"; hline; sleep 1; clear

  header "PREPARANDO SISTEMA"
  set_timezone
  install_with_progress "Localización en_US.UTF-8" "locale-gen en_US.UTF-8"
  install_with_progress "Fijando locale por defecto" "update-locale LANG=en_US.UTF-8"

  # Instalar net-tools temprano para detección IP/iface
  install_with_progress "Instalando net-tools" "apt-get update -y && apt-get install -y net-tools" || true

  echo; header "INSTALANDO VPS MÁSTER"

  # Descargar lista (con fallback)
  download_lista || true

  # Inicializar rutas y detectar red
  init_dirs
  detect_net
  echo

  # Dependencias (iterativo, estilo AGN)
  install_deps_iter

  # Configurar Apache
  setup_apache

  # Descargar módulos del proyecto y ejecutar
  download_modules
  run_installer
  function_verify

  # Limpieza
  [[ -e "$HOME/lista" ]] && rm -f "$HOME/lista"
  [[ -e "$HOME/fim"  ]] && rm -f "$HOME/fim"

  success_screen
}

main || error_exit
