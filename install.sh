#!/bin/bash

# ════════════════════════════════════════════════════════════════
# VPS MÁSTER - Sistema de Instalación Modular
# Creado por: SINNOMBRE22
# Fecha: 2025-10-17 20:34:37 UTC
# ════════════════════════════════════════════════════════════════

# 📁 Estructura de directorios (IGUAL A ANTES pero mejorada)
ADM_PATH="/etc/master-vps"
ADM_MODULES="${ADM_PATH}/modules"
ADM_DEPS="${ADM_PATH}/deps"
ADM_TMP="${ADM_PATH}/tmp"
ADM_BIN="${ADM_PATH}/bin"

# 🎨 Colores (tu configuración actual)
cor[1]="\033[1;36m"   # Cyan
cor[2]="\033[1;33m"   # Amarillo
cor[3]="\033[1;31m"   # Rojo
cor[5]="\033[1;32m"   # Verde
cor[4]="\033[0m"      # Reset

# ════════════════════════════════════════════════════════════════
# 📥 DESCARGA MODULAR DE DEPENDENCIAS (NUEVO - Como ADMRufu)
# ════════════════════════════════════════════════════════════════

download_deps(){
  # Lista de dependencias básicas para instalar
  soft="screen python lsof python3-pip unzip zip apache2 ufw figlet bc lynx curl git wget build-essential nano net-tools htop"
  
  echo -e "${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${cor[2]} Instalando Dependencias del Sistema"
  echo -e "${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  for paquete in $soft; do
    leng="${#paquete}"
    puntos=$(( 25 - $leng))
    pts="."
    
    for (( a = 0; a < $puntos; a++ )); do
      pts+="."
    done
    
    echo -ne "${cor[2]}  ► Instalando $paquete ${cor[3]}$pts${cor[4]} "
    
    if apt-get install $paquete -y &>/dev/null; then
      echo -e "${cor[5]}✓${cor[4]}"
    else
      echo -e "${cor[3]}✗${cor[4]}"
      # Retry una vez
      sleep 1
      if apt-get install $paquete -y &>/dev/null; then
        echo -e "${cor[5]}✓ (reintentado)${cor[4]}"
      else
        echo -e "${cor[3]}✗ Falló definitivamente${cor[4]}"
      fi
    fi
  done
}

# ════════════════════════════════════════════════════════════════
# 📦 DESCARGA DE MÓDULOS EXTERNOS (Como ADMRufu)
# ════════════════════════════════════════════════════════════════

download_modules(){
  # Repository base
  REPO_URL="https://raw.githubusercontent.com/SINNOMBRE22/master-vps/master"
  
  # Módulos a descargar
  modules_list=(
    "menu:${ADM_PATH}/menu"
    "cabecalho:${ADM_PATH}/cabecalho"
    "bashrc:${ADM_PATH}/bashrc"
    "verificar:${ADM_PATH}/verificar"
  )
  
  echo -e "${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${cor[2]} Descargando Módulos"
  echo -e "${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  for modulo_info in "${modules_list[@]}"; do
    modulo=$(echo $modulo_info | cut -d':' -f1)
    ruta=$(echo $modulo_info | cut -d':' -f2)
    
    echo -ne "${cor[2]}  ► Descargando $modulo${cor[3]}..."
    
    if wget -O "$ruta" "${REPO_URL}/modules/${modulo}" &>/dev/null; then
      chmod +x "$ruta" 2>/dev/null
      echo -e "${cor[5]} ✓${cor[4]}"
    else
      echo -e "${cor[3]} ✗ FALLO${cor[4]}"
      echo -e "${cor[3]}    Error: No se pudo descargar $modulo${cor[4]}"
      return 1  # Sale con error
    fi
  done
  
  return 0  # Éxito
}

# ════════════════════════════════════════════════════════════════
# 🔧 FUNCIÓN DE INICIALIZACIÓN (Mantiene TU configuración)
# ════════════════════════════════════════════════════════════════

init_directories(){
  # Crea la estructura EXACTA que ya tienes
  [[ -d "${ADM_PATH}" ]] && rm -rf "${ADM_PATH}"
  
  mkdir -p "${ADM_PATH}"
  mkdir -p "${ADM_MODULES}"
  mkdir -p "${ADM_DEPS}"
  mkdir -p "${ADM_TMP}"
  mkdir -p "${ADM_BIN}"
  
  # Comandos de acceso (como antes)
  echo "cd ${ADM_PATH} && bash ./menu" > /bin/menu
  echo "cd ${ADM_PATH} && bash ./menu" > /bin/vps
  chmod +x /bin/menu /bin/vps
  
  # Index HTML (como antes)
  touch "${ADM_PATH}/index.html"
  
  echo -e "${cor[5]}✓ Directorios creados correctamente${cor[4]}"
}

# ════════════════════════════════════════════════════════════════
# 🚀 FLUJO PRINCIPAL MEJORADO
# ════════════════════════════════════════════════════════════════

main_install(){
  clear
  
  echo -e "${cor[1]}════════════════════════════════════════════"
  echo -e "${cor[2]}  VPS MÁSTER - INSTALACIÓN MODULAR"
  echo -e "${cor[1]}════════════════════════════════════════════${cor[4]}"
  sleep 2
  
  # 1. Inicializar directorios
  echo -e "\n${cor[5]}[1/5] Preparando estructura...${cor[4]}"
  init_directories
  
  # 2. Actualizar sistema
  echo -e "\n${cor[5]}[2/5] Actualizando sistema...${cor[4]}"
  apt-get update -y &>/dev/null
  apt-get upgrade -y &>/dev/null
  
  # 3. Descargar dependencias
  echo -e "\n${cor[5]}[3/5] Descargando dependencias...${cor[4]}"
  download_deps
  
  # 4. Descargar módulos
  echo -e "\n${cor[5]}[4/5] Descargando módulos...${cor[4]}"
  if ! download_modules; then
    echo -e "\n${cor[3]}✗ Error en descarga de módulos${cor[4]}"
    error_fun
    return 1
  fi
  
  # 5. Finalizar
  echo -e "\n${cor[5]}[5/5] Finalizando instalación...${cor[4]}"
  
  # Copiar archivo de instalación para posterior uso
  cp -f $0 "${ADM_PATH}/install.sh"
  
  # Ejecutar cabecalho si existe
  [[ -x "${ADM_PATH}/cabecalho" ]] && cd "${ADM_PATH}" && bash cabecalho --instalar
  
  # Mensaje final
  clear
  echo -e "${cor[1]}════════════════════════════════════════════"
  echo -e "${cor[5]}  ✓ INSTALACIÓN COMPLETADA"
  echo -e "${cor[1]}════════════════════════════════════════════${cor[4]}"
  echo -e "${cor[2]}  Comandos disponibles:${cor[4]}"
  echo -e "${cor[5]}  • menu${cor[4]}"
  echo -e "${cor[5]}  • vps${cor[4]}"
  echo -e "${cor[1]}════════════════════════════════════════════${cor[4]}\n"
  
  return 0
}

# ════════════════════════════════════════════════════════════════
# ⚠️ MANEJO DE ERRORES
# ════════════════════════════════════════════════════════════════

error_fun(){
  clear
  echo -e "${cor[3]}════════════════════════════════════════════"
  echo -e "${cor[3]}  ✗ ERROR EN LA INSTALACIÓN"
  echo -e "${cor[3]}════════════════════════════════════════════${cor[4]}"
  echo -e "${cor[2]}  Opciones:${cor[4]}"
  echo -e "${cor[5]}  1. Reintentar instalación${cor[4]}"
  echo -e "${cor[5]}  2. Reparar repositorios${cor[4]}"
  echo -e "${cor[5]}  3. Salir${cor[4]}"
  echo -e "${cor[3]}════════════════════════════════════════════${cor[4]}\n"
  
  read -p "Selecciona opción: " -e -i 1 opcion
  
  case $opcion in
    1) main_install ;;
    2) 
      dpkg --configure -a &>/dev/null
      apt-get install -f -y &>/dev/null
      main_install
      ;;
    3) exit 1 ;;
  esac
}

# ════════════════════════════════════════════════════════════════
# 🎯 INICIO DEL SCRIPT
# ════════════════════════════════════════════════════════════════

# Validar que sea ROOT
if [[ ! $(id -u) = 0 ]]; then
  echo -e "${cor[3]}✗ DEBE EJECUTAR COMO ROOT${cor[4]}"
  exit 1
fi

# Control+C para salir limpio
trap "rm -rf ${ADM_TMP}/*; exit" INT TERM EXIT

# Eliminar script de sí mismo después de ejecutarse
rm $(pwd)/$0 &>/dev/null

# Ejecutar instalación
main_install

exit $?
