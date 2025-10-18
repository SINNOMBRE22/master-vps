#!/bin/bash
# =============================================================
# VPS MÁSTER - Instalador estilo AGN con colores del proyecto
# Proyecto: SINNOMBRE22/master-vps
# Fecha: 2025-10-18 10:12:43 UTC
# Versión: 3.1
# =============================================================

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Rutas del proyecto
ADM_PATH="/etc/master-vps"
REPO_URL="https://raw.githubusercontent.com/SINNOMBRE22/master-vps/master"
LOG_FILE="/var/log/vps-master-install.log"

# Colores (paleta de tu script)
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
MAGENTA='\033[1;35m'
RESET='\033[0m'

# ========================= UI estilo AGN =========================

msg() {
  BRAN='\033[1;37m'; BLACK='\e[1m'
  case $1 in
    -ne)  echo -ne "${RED}${BLACK}${2}${RESET}" ;;
    -ama) echo -e  "${YELLOW}${BLACK}${2}${RESET}" ;;
    -verm)echo -e  "${YELLOW}${BLACK}[!] ${RED}${2}${RESET}" ;;
    -azu) echo -e  "${CYAN}${BLACK}${2}${RESET}" ;;
    -verd)echo -e  "${GREEN}${BLACK}${2}${RESET}" ;;
    -bra) echo -ne "${RED}${2}${RESET}" ;;
    -gri) echo -ne "\e[5m\033[1;100m${2}${RESET}" ;;
    -bar) echo -e  "${CYAN}════════════════════════════════════════════════════════════${RESET}" ;;
    -bar2)echo -e  "${CYAN}────────────────────────────────────────────────────────────${RESET}" ;;
  esac
}

print_center() {
  local color="$1"; shift || true
  local text="$*"
  [[ -z "$text" ]] && read -r text
  while IFS= read -r line; do
    local space=""; local L=$(( (54 - ${#line}) / 2 ))
    (( L < 0 )) && L=0
    for ((i=0;i<L;i++)); do space+=' '; done
    if [[ -n "$color" ]]; then
      msg "$color" "${space}${line}"
    else
      msg -azu "${space}${line}"
    fi
  done <<<"$text"
}

title() {
  clear
  msg -bar
  print_center -azu "⇱ ${1} ⇲"
  msg -bar
}

fun_bar() {
  local comando="$1"
  ( bash -c "$comando" >>"$LOG_FILE" 2>&1 ) &
  local pid=$!
  while [[ -d /proc/$pid ]]; do
    echo -ne " ${YELLOW}["
    for ((i=0;i<20;i++)); do
      echo -ne "${RED}##"
      sleep 0.15
    done
    echo -ne "${YELLOW}]"
    sleep 0.4
    echo
    tput cuu1; tput dl1
  done
  echo -e " ${YELLOW}[\033[1;31m########################################\033[1;33m] - ${GREEN}100%${RESET}"
  sleep 0.5
}

# ===================== Utilidades y sistema =====================

ensure_log(){ : > "$LOG_FILE" || true; }

verify_root(){
  if [[ "$(id -u)" -ne 0 ]]; then
    title "ERROR DE EJECUCIÓN"
    print_center -verm "DEBE EJECUTAR COMO ROOT"
    msg -bar
    print_center -ama "Use: sudo bash install.sh"
    msg -bar
    exit 1
  fi
}

prep_locale(){
  title "PREPARANDO SISTEMA"
  print_center -ama "Configurando locales (en_US.UTF-8)"
  fun_bar "locale-gen en_US.UTF-8"
  fun_bar "update-locale LANG=en_US.UTF-8"
}

init_paths(){
  title "INICIALIZANDO RUTAS"
  [[ -d "$ADM_PATH" ]] && rm -rf "$ADM_PATH"
  mkdir -p "$ADM_PATH"
  : > "$ADM_PATH/index.html"
  echo "cd $ADM_PATH && bash ./menu" > /bin/menu
  echo "cd $ADM_PATH && bash ./menu" > /bin/vps
  chmod +x /bin/menu /bin/vps
  print_center -verd "Rutas listas en: $ADM_PATH"
  sleep 1
}

download_lista(){
  title "DESCARGANDO LISTA DE MÓDULOS"
  fun_bar "wget -q -O \"$HOME/lista\" \"$REPO_URL/lista\" || curl -fsSL \"$REPO_URL/lista\" -o \"$HOME/lista\""
  if [[ ! -s "$HOME/lista" ]]; then
    print_center -verm "No se pudo descargar la lista"
    msg -bar
  else
    print_center -verd "Lista descargada correctamente"
  fi
  sleep 1
}

# ===================== Dependencias requeridas =====================

dependencias(){
  title "INSTALANDO DEPENDENCIAS"
  print_center -ama "Actualizando repositorios"
  fun_bar "apt-get update -y"
  print_center -ama "Actualizando paquetes del sistema"
  fun_bar "apt-get upgrade -y"

  msg -bar
  print_center -verd "INSTALANDO PAQUETES"
  msg -bar

  local soft="git wget curl python3 python3-pip python-is-python3 \
build-essential openssl screen cron iptables apache2 ufw nano \
net-tools lsof zip unzip figlet bc gawk grep at mlocate locales jq \
ca-certificates"

  for pkg in $soft; do
    local dots="....................."
    local pad=$((21 - ${#pkg})); [[ $pad -lt 0 ]] && pad=0
    local pts="${dots:0:$pad}"
    echo -ne "    ${CYAN}installing ${pkg}${RESET}"
    echo -ne "${pts// /.}"
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

  # Asegurar alias python/pip si faltan
  command -v python >/dev/null 2>&1 || ln -sf /usr/bin/python3 /usr/bin/python
  command -v pip >/dev/null 2>&1 || ln -sf /usr/bin/pip3 /usr/bin/pip

  msg -bar
  print_center -verd "Dependencias listas"
  sleep 1
}

# ===================== Módulos del proyecto =====================

download_modules(){
  title "DESCARGANDO MÓDULOS"
  if [[ -s "$HOME/lista" ]]; then
    ( cd "$ADM_PATH" && fun_bar "wget -q -i \"$HOME/lista\"" )
    chmod +x "$ADM_PATH"/* >/dev/null 2>&1 || true
    print_center -verd "Módulos descargados"
  else
    print_center -ama "No hay lista, omitiendo descarga"
  fi
  sleep 1
}

run_installer(){
  title "EJECUTANDO INSTALADOR"
  if [[ -f "$ADM_PATH/cabecalho" ]]; then
    fun_bar "bash \"$ADM_PATH/cabecalho\" --instalar"
    print_center -verd "Instalador ejecutado"
  else
    print_center -ama "Módulo 'cabecalho' no encontrado"
  fi
  sleep 1
}

function_verify(){
  # Crea /bin/verifysys con 'verify' (ruta en hex)
/bin/true >/dev/null 2>&1
  local phex="2f62696e2f766572696679737973"
  local path; path=$(echo -e "$(echo "$phex" | sed 's/../\\x&/g')")
  echo "verify" > "$path" 2>/dev/null || true
}

# ===================== Finalización =====================

finish_screen(){
  title "✅ INSTALACIÓN COMPLETADA"
  print_center -verd "¡BIENVENIDO A VPS MÁSTER!"
  echo
  print_center -ama "Comandos disponibles:"
  print_center -azu "• menu"
  print_center -azu "• vps"
  echo
  print_center -ama "Ruta: $ADM_PATH"
  print_center -ama "$(date -u '+%Y-%m-%d %H:%M:%S') (UTC)"
  msg -bar
}

error_exit(){
  title "⚠️ ERROR DE INSTALACIÓN"
  print_center -verm "Ocurrió un error durante la instalación"
  print_center -ama "Revise el log:"
  print_center -azu "$LOG_FILE"
  msg -bar
  exit 1
}

# ===================== Flujo principal =====================

main(){
  ensure_log
  verify_root

  title "VPS MÁSTER (Diseño AGN • Colores del Proyecto)"
  print_center -ama "Creado por: SINNOMBRE22"
  msg -bar
  sleep 1

  prep_locale
  init_paths
  download_lista
  dependencias

  # NO tocar configuración de Apache (pedido del autor)

  download_modules
  run_installer
  function_verify

  # Limpieza
  [[ -e "$HOME/lista" ]] && rm -f "$HOME/lista"

  finish_screen
}

main || error_exit
