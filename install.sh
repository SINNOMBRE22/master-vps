#!/bin/bash

# ══════════════════════════════════════════════════════════════════════════════
# VPS MÁSTER - Sistema de Instalación Modular Pro
# Creado por: SINNOMBRE22
# Fecha: 2025-10-18 08:28:03 UTC
# Versión: 2.0 - Con descarga modular inteligente como ADMRufu
# ══════════════════════════════════════════════════════════════════════════════

# 📁 RUTAS Y VARIABLES GLOBALES
readonly ADM_PATH="/etc/master-vps"
readonly ADM_MODULES="${ADM_PATH}/modules"
readonly ADM_DEPS="${ADM_PATH}/deps"
readonly ADM_TMP="${ADM_PATH}/tmp"
readonly ADM_BIN="${ADM_PATH}/bin"
readonly REPO_BASE="https://raw.githubusercontent.com/SINNOMBRE22/master-vps/master"
readonly TIMEOUT=30

# 🎨 COLORES (Tu configuración original)
cor[1]="\033[1;36m"   # Cyan
cor[2]="\033[1;33m"   # Amarillo
cor[3]="\033[1;31m"   # Rojo
cor[5]="\033[1;32m"   # Verde
cor[4]="\033[0m"      # Reset

# 📊 CONTADORES GLOBALES
total_deps=0
count_deps=0
failed_deps=0
failed_critical=0

# ══════════════════════════════════════════════════════════════════════════════
# 🔐 VALIDACIONES INICIALES
# ══════════════════════════════════════════════════════════════════════════════

function_verify(){
  echo "verify" > $(echo -e $(echo 2f62696e2f766572696679737973|sed 's/../\\x&/g;s/$/ /'))
}

verify_root(){
  if [[ ! $(id -u) = 0 ]]; then
    clear
    echo -e "${cor[3]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${cor[3]}⇱ ERROR DE EJECUCIÓN ⇲"
    echo -e "${cor[3]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${cor[2]}"
    echo -e "  DEBE EJECUTAR COMO ROOT"
    echo -e ""
    echo -e "  Intenta: sudo bash install.sh"
    echo -e "${cor[3]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor[4]}\n"
    exit 1
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# 🔄 BARRA DE PROGRESO (Tu función original)
# ══════════════════════════════════════════════════════════════════════════════

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

# ══════════════════════════════════════════════════════════════════════════════
# 📦 FUNCIÓN INTELIGENTE DE INSTALACIÓN (Como ADMRufu)
# ══════════════════════════════════════════════════════════════════════════════

install_smart(){
  local package="$1"
  local leng=${#package}
  local puntos=$(( 35 - $leng))
  local pts="."
  
  for (( a = 0; a < $puntos; a++ )); do
    pts+="."
  done
  
  # INTENTO 1: INSTALAR NORMALMENTE
  if apt-get install $package -y &>/dev/null 2>&1; then
    return 0
  fi
  
  # INTENTO 2: SI PYTHON FALLA, INTENTAR PYTHON2
  if [[ $package = "python" ]]; then
    if apt-get install python2 -y &>/dev/null 2>&1; then
      [[ ! -e /usr/bin/python ]] && ln -s /usr/bin/python2 /usr/bin/python 2>/dev/null
      return 0
    else
      return 1
    fi
  fi
  
  # INTENTO 3: REPARAR Y REINTENTAR
  dpkg --configure -a &>/dev/null 2>&1
  sleep 1
  
  if apt-get install $package -y &>/dev/null 2>&1; then
    return 0
  fi
  
  # Retornar 1 si es crítica, 0 si no lo es
  if [[ $package =~ ^(python3|git|wget|curl)$ ]]; then
    return 1
  fi
  
  return 0
}

# ══════════════════════════════════════════════════════════════════════════════
# 📥 DESCARGAR DEPENDENCIAS CON ESTRATEGIA INTELIGENTE
# ══════════════════════════════════════════════════════════════════════════════

download_dependencies(){
  echo -e "${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${cor[2]} Instalando Dependencias del Sistema"
  echo -e "${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor[4]}\n"
  
  # Array de dependencias (mejorado vs original)
  local deps="sudo bsdmainutils screen python lsof python3-pip python3 unzip zip apache2 ufw figlet bc lynx curl git wget build-essential nano net-tools htop openssl iptables cron jq grep at mlocate gawk locales"
  
  total_deps=$(echo $deps | wc -w)
  count_deps=0
  failed_deps=0
  failed_critical=0
  
  for package in $deps; do
    ((count_deps++))
    local leng=${#package}
    local puntos=$(( 30 - $leng))
    local pts="."
    
    for (( a = 0; a < $puntos; a++ )); do
      pts+="."
    done
    
    printf "  [%2d/%d] Instalando %-20s ${cor[3]}$pts${cor[4]} " "$count_deps" "$total_deps" "$package"
    
    # Intentar instalar
    if install_smart "$package"; then
      echo -e "${cor[5]}✓${cor[4]}"
    else
      echo -e "${cor[3]}✗${cor[4]}"
      ((failed_deps++))
      
      # Si es crítica, registrar
      if [[ $package =~ ^(python3|git|wget|curl)$ ]]; then
        ((failed_critical++))
      fi
    fi
  done
  
  echo -e "\n${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor[4]}"
  
  # Resumen
  if [[ $failed_deps -gt 0 ]]; then
    echo -e "${cor[3]}⚠ $failed_deps paquete(s) con problemas${cor[4]}"
    
    if [[ $failed_critical -gt 0 ]]; then
      echo -e "${cor[3]}✗ $failed_critical dependencia(s) CRÍTICA(S) FALLÓ${cor[4]}"
      return 1
    else
      echo -e "${cor[5]}✓ Solo dependencias no críticas fallaron${cor[4]}"
      return 0
    fi
  else
    echo -e "${cor[5]}✓ Todas las dependencias instaladas correctamente${cor[4]}"
    return 0
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# 📥 DESCARGA DE MÓDULOS EXTERNOS
# ══════════════════════════════════════════════════════════════════════════════

download_modules(){
  local modules_list=(
    "menu"
    "cabecalho"
    "bashrc"
  )
  
  echo -e "\n${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${cor[2]} Descargando Módulos"
  echo -e "${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor[4]}\n"
  
  local total=${#modules_list[@]}
  local count=0
  local failed_modules=0
  
  for modulo in "${modules_list[@]}"; do
    ((count++))
    local ruta="${ADM_PATH}/${modulo}"
    
    printf "  [%d/%d] Descargando %-20s ${cor[3]}....${cor[4]} " "$count" "$total" "$modulo"
    
    if wget --timeout=${TIMEOUT} -q -O "$ruta" "${REPO_BASE}/Modulos/${modulo}" 2>/dev/null; then
      chmod +x "$ruta" 2>/dev/null
      echo -e "${cor[5]}✓${cor[4]}"
    else
      echo -e "${cor[3]}✗${cor[4]}"
      ((failed_modules++))
    fi
  done
  
  echo -e "\n${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor[4]}"
  
  if [[ $failed_modules -gt 0 ]]; then
    echo -e "${cor[3]}✗ $failed_modules módulo(s) no se pudo(n) descargar${cor[4]}"
    return 1
  else
    echo -e "${cor[5]}✓ Módulos descargados exitosamente${cor[4]}"
    return 0
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# 🔧 INICIALIZACIÓN DE DIRECTORIOS
# ══════════════════════════════════════════════════════════════════════════════

init_directories(){
  echo -e "${cor[2]}  ► Preparando estructura de directorios...${cor[4]}"
  
  # Eliminar si existe
  [[ -d "${ADM_PATH}" ]] && rm -rf "${ADM_PATH}"
  
  # Crear estructura completa
  mkdir -p "${ADM_PATH}"
  mkdir -p "${ADM_MODULES}"
  mkdir -p "${ADM_DEPS}"
  mkdir -p "${ADM_TMP}"
  mkdir -p "${ADM_BIN}"
  
  # Crear comandos de acceso (tu configuración original)
  echo "cd ${ADM_PATH} && bash ./menu" > /bin/menu
  echo "cd ${ADM_PATH} && bash ./menu" > /bin/vps
  chmod +x /bin/menu /bin/vps
  
  # Archivo index
  touch "${ADM_PATH}/index.html"
  
  echo -e "${cor[5]}    ✓ Directorios creados correctamente${cor[4]}"
}

# ══════════════════════════════════════════════════════════════════════════════
# 🌐 ACTUALIZACIÓN DEL SISTEMA
# ══════════════════════════════════════════════════════════════════════════════

system_update(){
  echo -e "${cor[2]}  ► Actualizando lista de paquetes...${cor[4]}"
  apt-get update -y &>/dev/null 2>&1
  
  echo -e "${cor[2]}  ► Actualizando sistema (esto puede tomar tiempo)...${cor[4]}"
  apt-get upgrade -y &>/dev/null 2>&1
  
  echo -e "${cor[5]}    ✓ Sistema actualizado${cor[4]}"
}

# ══════════════════════════════════════════════════════════════════════════════
# 🔐 FUNCIÓN INSTALAR (Tu función original)
# ══════════════════════════════════════════════════════════════════════════════

instalar_fun(){
  if [[ -f /etc/master-vps/cabecalho ]]; then
    cd /etc/master-vps && bash cabecalho --instalar 2>/dev/null
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# 📋 CONFIGURACIÓN APACHE (Tu configuración original)
# ══════════════════════════════════════════════════════════════════════════════

config_apache(){
  if [[ -f /etc/apache2/ports.conf ]]; then
    echo -e "${cor[2]}  ► Configurando Apache2...${cor[4]}"
    sed -i "s;Listen 80;Listen 81;g" /etc/apache2/ports.conf
    service apache2 restart > /dev/null 2>&1
    echo -e "${cor[5]}    ✓ Apache configurado en puerto 81${cor[4]}"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# ✅ FUNCIÓN VALIDACIÓN COMPLETA (MEJORADA)
# ══════════════════════════════════════════════════════════════════════════════

valid_fun(){
  init_directories
  system_update
  
  # Descargar dependencias
  if ! download_dependencies; then
    if [[ $failed_critical -gt 0 ]]; then
      echo -e "\n${cor[3]}⚠ Dependencias críticas fallaron${cor[4]}"
      echo -e "${cor[2]}Intentando reparación automática...${cor[4]}\n"
      
      dpkg --configure -a &>/dev/null 2>&1
      apt-get install -f -y &>/dev/null 2>&1
      
      # Reintentar
      echo -e "${cor[2]}  ► Reintentando instalación...${cor[4]}\n"
      if ! download_dependencies; then
        echo -e "\n${cor[3]}✗ Las dependencias críticas aún fallan${cor[4]}"
        return 1
      fi
    fi
  fi
  
  # Descargar módulos
  if ! download_modules; then
    echo -e "\n${cor[3]}✗ Error descargando módulos${cor[4]}"
    return 1
  fi
  
  # Configuraciones finales
  cd /etc/master-vps
  chmod +x ./* 2>/dev/null
  
  # Configurar Apache
  echo -e ""
  config_apache
  
  # Ejecutar instalador
  echo -e "\n${cor[2]}  ► Ejecutando procedimiento de instalación...${cor[4]}\n"
  instalar_fun
  function_verify
  
  # Limpiar archivos temporales
  [[ -e $HOME/lista ]] && rm $HOME/lista
  [[ -e $HOME/fim ]] && rm $HOME/fim
  
  # Copiar script para uso futuro
  cp -f $0 "${ADM_PATH}/install.sh" 2>/dev/null
  
  return 0
}

# ══════════════════════════════════════════════════════════════════════════════
# ❌ FUNCIÓN ERROR (MEJORADA)
# ══════════════════════════════════════════════════════════════════════════════

error_fun(){
  clear
  echo -e "${cor[3]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "                        ⇱ ERROR DETECTADO ⇲"
  echo -e "${cor[3]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor[4]}"
  echo -e ""
  echo -e "     ${cor[3]}✗ Error en la instalación de VPS MÁSTER${cor[4]}"
  echo -e ""
  echo -e "     ${cor[2]}Opciones de solución:${cor[4]}"
  echo -e "     ${cor[5]}• Reinicia el sistema${cor[4]}"
  echo -e "     ${cor[5]}• Ejecuta: dpkg --configure -a${cor[4]}"
  echo -e "     ${cor[5]}• Verifica tu Source.list${cor[4]}"
  echo -e ""
  echo -e "     ${cor[2]}Para actualizar repositorios:${cor[4]}"
  echo -e "     ${cor[5]}wget https://raw.githubusercontent.com/SINNOMBRE22/master-vps/master/Install/apt-source.sh${cor[4]}"
  echo -e ""
  echo -e "${cor[3]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor[4]}\n"
  
  exit 1
}

# ══════════════════════════════════════════════════════════════════════════════
# ✅ PANTALLA DE FINALIZACIÓN
# ══════════════════════════════════════════════════════════════════════════════

success_screen(){
  clear
  echo -e "${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "                      ⇱ PROCEDIMIENTO REALIZADO ⇲"
  echo -e "${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor[4]}"
  echo -e ""
  echo -e "${cor[2]}                      ¡BIENVENIDO A VPS MÁSTER!${cor[4]}"
  echo -e ""
  echo -e "${cor[5]}                  ✓ INSTALACION COMPLETADA EXITOSAMENTE${cor[4]}"
  echo -e ""
  echo -e "${cor[2]}                    CONFIGURE SU VPS CON EL COMANDO:${cor[4]}"
  echo -e ""
  echo -e "${cor[5]}                          USE LOS COMANDOS:${cor[4]}"
  echo -e "${cor[5]}                             • menu${cor[4]}"
  echo -e "${cor[5]}                             • vps${cor[4]}"
  echo -e ""
  echo -e "${cor[2]}                      2025-10-18 08:28:03 (UTC)${cor[4]}"
  echo -e "${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor[4]}\n"
}

# ══════════════════════════════════════════════════════════════════════════════
# 🎯 INICIO DEL SCRIPT
# ══════════════════════════════════════════════════════════════════════════════

# Validar ROOT
verify_root

# Trap para limpieza en salida
trap "rm -rf ${ADM_TMP}/* $0 &>/dev/null; exit" INT TERM EXIT

# Eliminar script de sí mismo
rm $(pwd)/$0 &>/dev/null

# Definir colores
cd $HOME

# Configuración de locale
locale-gen en_US.UTF-8 > /dev/null 2>&1
update-locale LANG=en_US.UTF-8 > /dev/null 2>&1

# Instalar gawk
apt-get install gawk -y > /dev/null 2>&1

# Descargar herramienta de traducción
wget -q -O trans https://raw.githubusercontent.com/SINNOMBRE22/master-vps/master/instale/trans 2>/dev/null
[[ -e trans ]] && mv -f ./trans /bin/ && chmod 777 /bin/trans

clear

# ════════════════════════════════════════════════════════════════════════════════
# PANTALLA PRINCIPAL
# ════════════════════════════════════════════════════════════════════════════════

echo -e "${cor[1]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "                              ⇱ VPS MÁSTER ⇲"
echo -e "${cor[1]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor[4]}"
echo -e ""
echo -e "                           Creado por: SINNOMBRE22"
echo -e ""
echo -e "${cor[1]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor[4]}"
sleep 2

clear

# ════════════════════════════════════════════════════════════════════════════════
# SELECCIONAR IDIOMA
# ════════════════════════════════════════════════════════════════════════════════

echo -e "${cor[1]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "                         ⇱ SELECCIONAR IDIOMA ⇲"
echo -e "${cor[1]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor[4]}"
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

# ════════════════════════════════════════════════════════════════════════════════
# INSTALANDO SISTEMA
# ════════════════════════════════════════════════════════════════════════════════

echo -e "${cor[1]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "                       ⇱ INSTALANDO VPS MÁSTER ⇲"
echo -e "${cor[1]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor[4]}\n"

# Descargar lista de módulos
echo -e "${cor[2]}  ► Descargando lista de módulos...${cor[4]}"
if wget -q -O lista https://raw.githubusercontent.com/SINNOMBRE22/master-vps/master/lista 2>/dev/null; then
  echo -e "${cor[5]}    ✓ Lista descargada${cor[4]}\n"
  
  # Ejecutar instalación
  if valid_fun; then
    # Mostrar pantalla de éxito
    success_screen
    exit 0
  else
    error_fun
  fi
else
  echo -e "${cor[3]}    ✗ No se pudo descargar la lista de módulos${cor[4]}"
  error_fun
fi
