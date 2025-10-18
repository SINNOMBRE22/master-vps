#!/bin/bash

# ══════════════════════════════════════════════════════════
# VPS MÁSTER - Sistema Instalación Modular Pro
# Creado por: SINNOMBRE22
# Fecha: 2025-10-18 09:07:03 UTC
# Versión: 2.0 PROFESIONAL
# ══════════════════════════════════════════════════════════

# 📁 VARIABLES GLOBALES
readonly ADM_PATH="/etc/master-vps"
readonly REPO_URL="https://raw.githubusercontent.com/SINNOMBRE22/master-vps/master"

# 🎨 COLORES
cor[1]="\033[1;36m"   # Cyan
cor[2]="\033[1;33m"   # Amarillo
cor[3]="\033[1;31m"   # Rojo
cor[5]="\033[1;32m"   # Verde
cor[4]="\033[0m"      # Reset

# ══════════════════════════════════════════════════════════
# 🔐 VALIDACIÓN
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
# 🔄 BARRA DE PROGRESO
# ══════════════════════════════════════════════════════════

fun_bar(){
  (
    [[ -e $HOME/fim ]] && rm $HOME/fim
    $1 > /dev/null 2>&1
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
# 🌐 DETECTAR SO Y REPOSITORIOS
# ══════════════════════════════════════════════════════════

setup_repos(){
  source /etc/os-release
  
  case $VERSION_ID in
    8*|9*|10*|11*|16.04*|18.04*|20.04*|22.04*)
      [[ ! -e /etc/apt/sources.list.back ]] && \
        cp /etc/apt/sources.list /etc/apt/sources.list.back
      
      wget -q -O /etc/apt/sources.list \
        "${REPO_URL}/Repositorios/${VERSION_ID}.list" 2>/dev/null
      ;;
  esac
}

# ══════════════════════════════════════════════════════════
# 📁 CREAR DIRECTORIOS
# ══════════════════════════════════════════════════════════

init_dirs(){
  [[ -d "${ADM_PATH}" ]] && rm -rf "${ADM_PATH}"
  mkdir -p "${ADM_PATH}"
  
  echo "cd ${ADM_PATH} && bash ./menu" > /bin/menu
  echo "cd ${ADM_PATH} && bash ./menu" > /bin/vps
  chmod +x /bin/menu /bin/vps
  
  touch "${ADM_PATH}/index.html"
}

# ══════════════════════════════════════════════════════════
# 📦 INSTALAR DEPENDENCIAS ESENCIALES
# ══════════════════════════════════════════════════════════

install_deps(){
  # LISTA ÚNICA Y ESENCIAL (sin duplicados)
  local deps="sudo git wget curl python python3"
  deps="$deps python3-pip build-essential openssl"
  deps="$deps screen cron iptables apache2 ufw"
  deps="$deps nano net-tools lsof zip unzip"
  deps="$deps figlet bc gawk grep at mlocate"
  deps="$deps locales jq"
  
  for pkg in $deps; do
    leng=${#pkg}
    puntos=$(( 21 - $leng))
    pts=""
    
    for (( a = 0; a < $puntos; a++ )); do
      pts+="."
    done
    
    echo -ne "${cor[2]}      instalando"
    echo -ne " $pkg"
    echo -ne " ${cor[3]}$pts${cor[4]}"
    
    # INSTALAR UNA SOLA VEZ
    if apt-get install $pkg -y &>/dev/null 2>&1; then
      echo -e "${cor[5]}INSTALL${cor[4]}"
    else
      echo -e "${cor[3]}FAIL${cor[4]}"
      sleep 2
      
      # FALLBACK SOLO PARA PYTHON
      if [[ $pkg = "python" ]]; then
        pts=$(echo ${pts:1})
        echo -ne "${cor[2]}      instalando"
        echo -ne " python2"
        echo -ne " ${cor[3]}$pts${cor[4]}"
        
        if apt-get install python2 -y &>/dev/null 2>&1; then
          [[ ! -e /usr/bin/python ]] && \
            ln -s /usr/bin/python2 /usr/bin/python 2>/dev/null
          echo -e "${cor[5]}INSTALL${cor[4]}"
        else
          echo -e "${cor[3]}FAIL${cor[4]}"
        fi
        continue
      fi
      
      # REPARAR Y REINTENTAR
      dpkg --configure -a &>/dev/null 2>&1
      sleep 1
      
      echo -ne "${cor[2]}      instalando"
      echo -ne " $pkg"
      echo -ne " ${cor[3]}$pts${cor[4]}"
      
      if apt-get install $pkg -y &>/dev/null 2>&1; then
        echo -e "${cor[5]}INSTALL${cor[4]}"
      else
        echo -e "${cor[3]}FAIL${cor[4]}"
      fi
    fi
  done
}

# ══════════════════════════════════════════════════════════
# 📥 DESCARGAR MÓDULOS DESDE LISTA
# ══════════════════════════════════════════════════════════

download_modules(){
  cd "${ADM_PATH}"
  
  echo -ne "${cor[2]}["
  wget -i $HOME/lista -o /dev/null 2>&1 &
  local pid=$!
  
  while kill -0 $pid 2>/dev/null; do
    for((i=0; i<18; i++)); do
      echo -ne "${cor[3]}##"
      sleep 0.1s
    done
    echo -e "${cor[2]}]"
    sleep 1s
    tput cuu1
    tput dl1
    echo -ne "${cor[2]}["
  done
  
  wait $pid
  echo -e "${cor[2]}]${cor[3]} -${cor[5]} 100%${cor[4]}"
  
  chmod +x ./* 2>/dev/null
}

# ══════════════════════════════════════════════════════════
# 🔐 EJECUTAR INSTALADOR
# ══════════════════════════════════════════════════════════

run_installer(){
  if [[ -f /etc/master-vps/cabecalho ]]; then
    cd /etc/master-vps && \
      bash cabecalho --instalar 2>/dev/null
  fi
}

# ══════════════════════════════════════════════════════════
# 📋 CONFIGURAR APACHE
# ══════════════════════════════════════════════════════════

setup_apache(){
  if [[ -f /etc/apache2/ports.conf ]]; then
    sed -i "s;Listen 80;Listen 81;g" \
      /etc/apache2/ports.conf
    service apache2 restart > /dev/null 2>&1
  fi
}

# ══════════════════════════════════════════════════════════
# ❌ ERROR
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
# ✅ ÉXITO
# ══════════════════════════════════════════════════════════

success_fun(){
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
  echo -e "              2025-10-18 09:07:03 (UTC)"
  echo -e "${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -ne "\033[0m"
}

# ══════════════════════════════════════════════════════════
# 🎯 FLUJO PRINCIPAL
# ══════════════════════════════════════════════════════════

verify_root
trap "rm -f $0 &>/dev/null; exit" INT TERM EXIT
rm $(pwd)/$0 &>/dev/null

cd $HOME

# Preparación
locale-gen en_US.UTF-8 > /dev/null 2>&1
update-locale LANG=en_US.UTF-8 > /dev/null 2>&1
apt-get install gawk -y > /dev/null 2>&1

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
# INSTALAR
# ════════════════════════════════════════════════════════════

echo -e "${cor[1]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "       ⇱ INSTALANDO VPS MÁSTER ⇲"
echo -e "${cor[1]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e ""

# Descargar lista
wget -q -O lista ${REPO_URL}/lista 2>/dev/null

if [[ $? -ne 0 ]]; then
  echo -e "${cor[3]}Error al descargar lista${cor[4]}"
  error_fun
fi

# Inicializar
init_dirs
setup_repos

# Actualizar sistema
echo -e "${cor[2]}Actualizando sistema..."
fun_bar "apt-get update -y"
fun_bar "apt-get upgrade -y"

# Instalar dependencias
echo -e "\n${cor[5]}Instalando dependencias..."
echo -e "${cor[3]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
install_deps

# Descargar módulos
echo -e "\n${cor[5]}Descargando módulos..."
echo -e "${cor[3]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
download_modules

# Finalizar
setup_apache
run_installer
function_verify

[[ -e $HOME/lista ]] && rm $HOME/lista
[[ -e $HOME/fim ]] && rm $HOME/fim

cp -f $0 "${ADM_PATH}/install.sh" 2>/dev/null

success_fun
exit 0
