#!/bin/bash

# ══════════════════════════════════════════════════════════
# VPS MÁSTER - Sistema Instalación Modular Pro
# Creado por: SINNOMBRE22
# Fecha: 2025-10-18 08:52:31 UTC
# Versión: 2.0 - ADMRufu Style
# ══════════════════════════════════════════════════════════

# 📁 VARIABLES GLOBALES
readonly ADM_PATH="/etc/master-vps"
readonly ADM_MODULES="${ADM_PATH}/modules"
readonly ADM_DEPS="${ADM_PATH}/deps"
readonly ADM_TMP="${ADM_PATH}/tmp"
readonly ADM_BIN="${ADM_PATH}/bin"
readonly REPO_BASE="https://raw.githubusercontent.com"
readonly REPO_URL="${REPO_BASE}/SINNOMBRE22/master-vps/master"
readonly TIMEOUT=30

# 🎨 COLORES
cor[1]="\033[1;36m"   # Cyan
cor[2]="\033[1;33m"   # Amarillo
cor[3]="\033[1;31m"   # Rojo
cor[5]="\033[1;32m"   # Verde
cor[4]="\033[0m"      # Reset

# 📊 CONTADORES
total_deps=0
count_deps=0
failed_deps=0
failed_critical=0

# ══════════════════════════════════════════════════════════
# 🔐 VALIDACIÓN INICIAL
# ══════════════════════════════════════════════════════════

function_verify(){
  echo "verify" > $(echo -e $(echo 2f62696e2f766572696679737973|sed 's/../\\x&/g;s/$/ /'))
}

verify_root(){
  if [[ ! $(id -u) = 0 ]]; then
    clear
    echo -e "${cor[3]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${cor[3]}⇱ ERROR DE EJECUCIÓN ⇲"
    echo -e "${cor[3]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${cor[2]}"
    echo -e "DEBE EJECUTAR COMO ROOT"
    echo -e ""
    echo -e "Intenta:"
    echo -e "sudo bash install.sh"
    echo -e "${cor[3]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor[4]}\n"
    exit 1
  fi
}

# ══════════════════════════════════════════════════════════
# 🌍 DETECTAR SISTEMA OPERATIVO
# ══════════════════════════════════════════════════════════

detect_system(){
  source /etc/os-release
  export VERSION_ID
}

# ══════════════════════════════════════════════════════════
# 🔄 CONFIGURAR REPOSITORIOS (Como ADMRufu)
# ══════════════════════════════════════════════════════════

repo_install(){
  local link="${REPO_URL}/Repositorios"
  
  echo -e "${cor[2]}Configurando repositorios${cor[4]}"
  echo -e "${cor[2]}para versión: $VERSION_ID${cor[4]}"
  
  case $VERSION_ID in
    8*|9*|10*|11*|16.04*|18.04*|20.04*|22.04*)
      # Crear backup
      if [[ ! -e /etc/apt/sources.list.back ]]; then
        cp /etc/apt/sources.list \
          /etc/apt/sources.list.back
      fi
      
      # Descargar nuevo sources.list
      if wget -q -O /etc/apt/sources.list \
        "${link}/${VERSION_ID}.list" 2>/dev/null; then
        echo -e "${cor[5]}✓ Repositorios"
        echo -e "configurados${cor[4]}"
      else
        echo -e "${cor[3]}⚠ No se descargó"
        echo -e "sources.list${cor[4]}"
      fi
      ;;
    12*|24.04*)
      echo -e "${cor[2]}Aplicando fix para"
      echo -e "Debian12/Ubuntu24${cor[4]}"
      
      if command -v ldd &>/dev/null; then
        local glibc=$(ldd --version | \
          head -1 | grep -o '[0-9]\+\.[0-9]\+' | \
          sed 's/\.//g' | head -1)
        
        if [[ -n $glibc && $glibc -ge 235 ]]; then
          wget -q -O /root/fix \
            "${REPO_URL}/fix" 2>/dev/null
          [[ -f /root/fix ]] && \
            chmod 755 /root/fix && /root/fix
        fi
      fi
      ;;
  esac
}

# ══════════════════════════════════════════════════════════
# 🔄 BARRA DE PROGRESO (Original VPS MÁSTER)
# ══════════════════════════════════════════════════════════

fun_bar(){
  comando[0]="$1"
  comando[1]="$2"
  (
    [[ -e $HOME/fim ]] && rm $HOME/fim
    ${comando[0]} -y > /dev/null 2>&1
    ${comando[1]} -y > /dev/null 2>&1
    touch $HOME/fim
  ) > /dev/null 2>&1 &
  
  echo -ne "${cor[2]}["
  while true; do
    for((i=0; i<18; i++)); do
      echo -ne "${cor[3]}##"
      sleep 0.1s
    done
    [[ -e $HOME/fim ]] && rm $HOME/fim && break
    echo -e "${cor[2]}]"
    sleep 1s
    tput cuu1
    tput dl1
    echo -ne "${cor[2]}["
  done
  echo -e "${cor[2]}]${cor[3]} -${cor[5]} 100%${cor[4]}"
}

# ══════════════════════════════════════════════════════════
# 📦 INSTALACIÓN INTELIGENTE (ADMRufu STYLE)
# ══════════════════════════════════════════════════════════

install_smart(){
  local package="$1"
  local leng=${#package}
  local puntos=$(( 21 - $leng))
  local pts="."
  
  for (( a = 0; a < $puntos; a++ )); do
    pts+="."
  done
  
  # INTENTO 1: INSTALAR
  if apt install $package -y &>/dev/null 2>&1; then
    return 0
  fi
  
  # INTENTO 2: SI PYTHON FALLA
  if [[ $package = "python" ]]; then
    pts=$(echo ${pts:1})
    echo -ne "${cor[2]}      instalando"
    echo -ne " python2"
    echo -ne " ${cor[3]}$pts${cor[4]}"
    
    if apt install python2 -y &>/dev/null 2>&1; then
      [[ ! -e /usr/bin/python ]] && \
        ln -s /usr/bin/python2 /usr/bin/python 2>/dev/null
      return 0
    else
      return 1
    fi
  fi
  
  # INTENTO 3: REPARAR Y REINTENTAR
  dpkg --configure -a &>/dev/null 2>&1
  sleep 2
  
  if apt install $package -y &>/dev/null 2>&1; then
    return 0
  fi
  
  # Retornar 1 si crítica
  if [[ $package =~ ^(python3|git|wget|curl)$ ]]; then
    return 1
  fi
  
  return 0
}

# ══════════════════════════════════════════════════════════
# 📥 DESCARGAR DEPENDENCIAS (ADMRufu STYLE)
# ══════════════════════════════════════════════════════════

download_dependencies(){
  local soft="sudo bsdmainutils zip unzip ufw curl"
  soft="$soft python python3 python3-pip openssl"
  soft="$soft screen cron iptables lsof nano at"
  soft="$soft mlocate gawk grep bc jq curl npm"
  soft="$soft nodejs socat netcat netcat-traditional"
  soft="$soft net-tools cowsay figlet lolcat"
  soft="$soft sqlite3 libsqlite3-dev locales"
  soft="$soft build-essential git wget htop"
  
  for install in $soft; do
    leng="${#install}"
    puntos=$(( 21 - $leng))
    pts="."
    
    for (( a = 0; a < $puntos; a++ )); do
      pts+="."
    done
    
    echo -ne "${cor[2]}      instalando"
    echo -ne " $install"
    echo -ne " ${cor[3]}$pts${cor[4]}"
    
    if apt install $install -y &>/dev/null 2>&1; then
      echo -e "${cor[5]}INSTALL${cor[4]}"
    else
      echo -e "${cor[3]}FAIL${cor[4]}"
      sleep 2
      
      if [[ $install = "python" ]]; then
        pts=$(echo ${pts:1})
        echo -ne "${cor[2]}      instalando"
        echo -ne " python2"
        echo -ne " ${cor[3]}$pts${cor[4]}"
        
        if apt install python2 -y &>/dev/null 2>&1; then
          [[ ! -e /usr/bin/python ]] && \
            ln -s /usr/bin/python2 /usr/bin/python 2>/dev/null
          echo -e "${cor[5]}INSTALL${cor[4]}"
        else
          echo -e "${cor[3]}FAIL${cor[4]}"
        fi
        continue
      fi
      
      echo -e "${cor[2]}aplicando fix a $install"
      dpkg --configure -a &>/dev/null 2>&1
      sleep 2
      
      echo -ne "${cor[2]}      instalando"
      echo -ne " $install"
      echo -ne " ${cor[3]}$pts${cor[4]}"
      
      if apt install $install -y &>/dev/null 2>&1; then
        echo -e "${cor[5]}INSTALL${cor[4]}"
      else
        echo -e "${cor[3]}FAIL${cor[4]}"
        ((failed_deps++))
      fi
    fi
  done
}

# ══════════════════════════════════════════════════════════
# 📥 DESCARGA DE MÓDULOS
# ══════════════════════════════════════════════════════════

download_modules(){
  local modules_list=(
    "menu"
    "cabecalho"
    "bashrc"
  )
  
  for modulo in "${modules_list[@]}"; do
    local ruta="${ADM_PATH}/${modulo}"
    
    if wget --timeout=${TIMEOUT} -q -O "$ruta" \
      "${REPO_URL}/Modulos/${modulo}" 2>/dev/null; then
      chmod +x "$ruta" 2>/dev/null
    else
      echo -e "${cor[3]}Falla al descargar"
      echo -e "$modulo${cor[4]}"
      echo -e "${cor[2]}Reportar con el"
      echo -e "administrador @SINNOMBRE22"
      return 1
    fi
  done
  
  return 0
}

# ══════════════════════════════════════════════════════════
# 🔧 INICIALIZAR DIRECTORIOS
# ══════════════════════════════════════════════════════════

init_directories(){
  [[ -d "${ADM_PATH}" ]] && rm -rf "${ADM_PATH}"
  
  mkdir -p "${ADM_PATH}"
  mkdir -p "${ADM_MODULES}"
  mkdir -p "${ADM_DEPS}"
  mkdir -p "${ADM_TMP}"
  mkdir -p "${ADM_BIN}"
  
  echo "cd ${ADM_PATH} && bash ./menu" > /bin/menu
  echo "cd ${ADM_PATH} && bash ./menu" > /bin/vps
  chmod +x /bin/menu /bin/vps
  
  touch "${ADM_PATH}/index.html"
}

# ══════════════════════════════════════════════════════════
# 🌐 ACTUALIZAR SISTEMA
# ══════════════════════════════════════════════════════════

system_update(){
  apt-get update -y &>/dev/null 2>&1
  apt-get upgrade -y &>/dev/null 2>&1
}

# ══════════════════════════════════════════════════════════
# 🔐 FUNCIÓN INSTALAR
# ══════════════════════════════════════════════════════════

instalar_fun(){
  if [[ -f /etc/master-vps/cabecalho ]]; then
    cd /etc/master-vps && bash cabecalho --instalar 2>/dev/null
  fi
}

# ══════════════════════════════════════════════════════════
# 📋 CONFIGURACIÓN APACHE
# ══════════════════════════════════════════════════════════

config_apache(){
  if [[ -f /etc/apache2/ports.conf ]]; then
    sed -i "s;Listen 80;Listen 81;g" \
      /etc/apache2/ports.conf
    service apache2 restart > /dev/null 2>&1
  fi
}

# ══════════════════════════════════════════════════════════
# ✅ VALIDACIÓN COMPLETA
# ══════════════════════════════════════════════════════════

valid_fun(){
  init_directories
  
  # NUEVO: Configurar repositorios primero
  repo_install
  
  system_update
  
  echo -e "${cor[5]} $(source trans -b pt:${id} \
    "INSTALANDO DEPENDENCIAS")"
  echo -e "${cor[3]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  download_dependencies
  
  echo -e "${cor[5]} $(source trans -b pt:${id} \
    "DESCARGANDO MÓDULOS")"
  echo -e "${cor[3]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  if ! download_modules; then
    error_fun
    return 1
  fi
  
  cd /etc/master-vps
  chmod +x ./* 2>/dev/null
  
  config_apache
  
  instalar_fun
  function_verify
  
  [[ -e $HOME/lista ]] && rm $HOME/lista
  [[ -e $HOME/fim ]] && rm $HOME/fim
  
  cp -f $0 "${ADM_PATH}/install.sh" 2>/dev/null
  
  return 0
}

# ══════════════════════════════════════════════════════════
# ❌ FUNCIÓN ERROR
# ══════════════════════════════════════════════════════════

error_fun(){
  echo -e "${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "\033[1;31mYour apt-get Error!"
  echo -e "Reboot the System!"
  echo -e "Use Command:"
  echo -e "\033[1;36mdpkg --configure -a"
  echo -e "\033[1;31mVerify your"
  echo -e "Source.list"
  echo -e "For Update Source list"
  echo -e "use this command"
  echo -e "\033[1;36mwget https://raw."
  echo -e "githubusercontent.com/"
  echo -e "SINNOMBRE22/master-vps/"
  echo -e "master/instale/"
  echo -e "apt-source.sh"
  echo -e "${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -ne "\033[0m"
  exit 1
}

# ══════════════════════════════════════════════════════════
# ✅ PANTALLA DE ÉXITO
# ══════════════════════════════════════════════════════════

success_screen(){
  clear
  echo -e "${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "                ⇱ PROCEDIMIENTO REALIZADO ⇲"
  echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e ""
  echo -e "                ¡BIENVENIDO A VPS MÁSTER!"
  echo -e ""
  echo -e "            ✓ INSTALACION COMPLETADA"
  echo -e "              EXITOSAMENTE"
  echo -e ""
  echo -e "              CONFIGURE SU VPS CON EL"
  echo -e "              COMANDO:"
  echo -e ""
  echo -e "              USE LOS COMANDOS:"
  echo -e "                 • menu"
  echo -e "                 • vps"
  echo -e ""
  echo -e "              2025-10-18 08:52:31 (UTC)"
  echo -e "${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -ne "\033[0m"
}

# ══════════════════════════════════════════════════════════
# 🎯 INICIO DEL SCRIPT
# ══════════════════════════════════════════════════════════

verify_root

trap "rm -rf ${ADM_TMP}/* $0 &>/dev/null; exit" \
  INT TERM EXIT

rm $(pwd)/$0 &>/dev/null

cd $HOME

locale-gen en_US.UTF-8 > /dev/null 2>&1
update-locale LANG=en_US.UTF-8 > /dev/null 2>&1

apt-get install gawk -y > /dev/null 2>&1

# DETECTAR SO PRIMERO
detect_system

wget -q -O trans \
  ${REPO_URL}/instale/trans 2>/dev/null
[[ -e trans ]] && mv -f ./trans /bin/ && \
  chmod 777 /bin/trans

clear

# ════════════════════════════════════════════════════════════
# PANTALLA PRINCIPAL
# ════════════════════════════════════════════════════════════

echo -e "${cor[1]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "              ⇱ VPS MÁSTER ⇲"
echo -e "${cor[1]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e ""
echo -e "         Creado por: SINNOMBRE22"
echo -e ""
echo -e "${cor[1]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sleep 2

clear

# ════════════════════════════════════════════════════════════
# SELECCIONAR IDIOMA
# ════════════════════════════════════════════════════════════

echo -e "${cor[1]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "         ⇱ SELECCIONAR IDIOMA ⇲"
echo -e "${cor[1]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e ""
echo -e "     ${cor[5]}[1] - PT-BR 🇧🇷${cor[4]}"
echo -e "     ${cor[5]}[2] - EN 🇺🇸${cor[4]}"
echo -e "     ${cor[5]}[3] - ES 🇪🇸${cor[4]}"
echo -e "     ${cor[5]}[4] - FR 🇫🇷${cor[4]}"
echo -e ""
echo -ne "     ${cor[2]}SELECCIONA TU OPCION: ${cor[4]}"
read lang

case $lang in
  1) id="pt" ;;
  2) id="en" ;;
  3) id="es" ;;
  4) id="fr" ;;
  *) id="es" ;;
esac

clear

# ════════════════════════════════════════════════════════════
# INSTALANDO SISTEMA
# ════════════════════════════════════════════════════════════

echo -e "${cor[1]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "       ⇱ INSTALANDO VPS MÁSTER ⇲"
echo -e "${cor[1]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e ""

wget -q -O lista \
  ${REPO_URL}/lista 2>/dev/null

if [[ $? -eq 0 ]]; then
  if valid_fun; then
    success_screen
    exit 0
  else
    error_fun
  fi
else
  echo -e "${cor[3]}Error al descargar"
  echo -e "lista de módulos${cor[4]}"
  error_fun
fi
