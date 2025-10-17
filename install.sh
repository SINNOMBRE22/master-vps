#!/bin/bash

# ════════════════════════════════════════════════════════════════════
# VPS MÁSTER - Sistema de Instalación
# Creado por: SINNOMBRE22
# Fecha: 2025-10-17 20:34:37 UTC
# ════════════════════════════════════════════════════════════════════

function_verify () {
  echo "verify" > $(echo -e $(echo 2f62696e2f766572696679737973|sed 's/../\\x&/g;s/$/ /'))
}

fun_bar () {
comando[0]="$1"
comando[1]="$2"
 (
[[ -e $HOME/fim ]] && rm $HOME/fim
${comando[0]} -y > /dev/null 2>&1
${comando[1]} -y > /dev/null 2>&1
touch $HOME/fim
 ) > /dev/null 2>&1 &
echo -ne "\033[1;33m ["
while true; do
   for((i=0; i<18; i++)); do
   echo -ne "\033[1;31m##"
   sleep 0.1s
   done
   [[ -e $HOME/fim ]] && rm $HOME/fim && break
   echo -e "\033[1;33m]"
   sleep 1s
   tput cuu1
   tput dl1
   echo -ne "\033[1;33m ["
done
echo -e "\033[1;33m]\033[1;31m -\033[1;32m 100%\033[1;37m"
}

instalar_fun () {
cd /etc/vps-master && bash cabecalho --instalar
}

elimined_fun () {
text=$(source trans -b pt:${id} "Instalando")
echo -e "${cor[2]} Update"
fun_bar 'apt-get install screen' 'apt-get install python'
echo -e "${cor[2]} Upgrade"
fun_bar 'apt-get install lsof' 'apt-get install python3-pip'
echo -e "${cor[2]} $text Lsof"
fun_bar 'apt-get install python' 'apt-get install unzip'
echo -e "${cor[2]} $text Python3"
fun_bar 'apt-get install zip' 'apt-get install apache2'
echo -e "${cor[2]} $text Unzip"
fun_bar 'apt-get install ufw'
echo -e "${cor[2]} $text Screen"
fun_bar 'apt-get install figlet' 'apt-get install bc'
echo -e "${cor[2]} $text Figlet"
fun_bar 'apt-get install lynx' 'apt-get install curl'
sed -i "s;Listen 80;Listen 81;g" /etc/apache2/ports.conf
service apache2 restart > /dev/null 2>&1
}

valid_fun () {
[[ -d /etc/vps-master ]] && rm -rf /etc/vps-master
mkdir /etc/vps-master
cd /etc/vps-master
echo "cd /etc/vps-master && bash ./menu" > /bin/menu
echo "cd /etc/vps-master && bash ./menu" > /bin/vps
chmod +x /bin/menu
chmod +x /bin/vps
cd /etc/vps-master
touch /etc/vps-master/index.html
wget -i $HOME/lista -o /dev/null
wget -O trans https://raw.githubusercontent.com/SINNOMBRE22/master-vps/master/Modulo/michu -o /dev/null 2>&1
echo -e "${cor[5]} $(source trans -b pt:${id} "INSTALANDO DEPENDENCIAS")"
echo -e "${cor[3]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd /etc/vps-master
chmod +x ./*
instalar_fun
function_verify
[[ -e $HOME/lista ]] && rm $HOME/lista
clear
echo -e "${cor[5]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "                      ⇱ PROCEDIMIENTO REALIZADO ⇲"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e ""
echo -e "                      ¡BIENVENIDO A VPS MÁSTER!"
echo -e ""
echo -e "                  ✓ INSTALACION COMPLETADA EXITOSAMENTE"
echo -e ""
echo -e "                    CONFIGURE SU VPS CON EL COMANDO:"
echo -e ""
echo -e "                          USE LOS COMANDOS:"
echo -e "                             • menu"
echo -e "                             • vps"
echo -e ""
echo -e "                      2025-10-17 20:34:37 (UTC)"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -ne "\033[0m"
}

error_fun () {
clear
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "                        ⇱ ERROR DETECTADO ⇲"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e ""
echo -e "     ✗ Your apt-get Error!"
echo -e ""
echo -e "     • Reinicia el sistema"
echo -e "     • Ejecuta: dpkg --configure -a"
echo -e "     • Verifica tu Source.list"
echo -e ""
echo -e "     wget https://raw.githubusercontent.com/SINNOMBRE22/master-vps/"
echo -e "             master/Install/apt-source.sh"
echo -e ""
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -ne "\033[0m"
exit 1
}

# ════════════════════════════════════════════════════════════════════
# INICIO DEL SCRIPT
# ════════════════════════════════════════════════════════════════════

rm $(pwd)/$0

# Definir colores
cor[1]="\033[1;36m"   # Cyan
cor[2]="\033[1;33m"   # Amarillo
cor[3]="\033[1;31m"   # Rojo
cor[5]="\033[1;32m"   # Verde
cor[4]="\033[0m"      # Reset

cd $HOME
locale-gen en_US.UTF-8 > /dev/null 2>&1
update-locale LANG=en_US.UTF-8 > /dev/null 2>&1
apt-get install gawk -y > /dev/null 2>&1
wget -O trans https://raw.githubusercontent.com/SINNOMBRE22/master-vps/master/Install/trans -o /dev/null 2>&1
mv -f ./trans /bin/ && chmod 777 /bin/*

clear

# Pantalla Principal
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "                              ⇱ VPS MÁSTER ⇲"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e ""
echo -e "                           Creado por: SINNOMBRE22"
echo -e ""
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sleep 2

clear

# Seleccionar Idioma
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "                         ⇱ SELECCIONAR IDIOMA ⇲"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e ""
echo -e "     [1] - PT-BR 🇧🇷"
echo -e "     [2] - EN 🇺🇸"
echo -e "     [3] - ES 🇪🇸"
echo -e "     [4] - FR 🇫🇷"
echo -e ""
echo -e "     SELECCIONA TU OPCION: \c"
read lang
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

case $lang in
1)
id="pt"
;;
2)
id="en"
;;
3)
id="es"
;;
4)
id="fr"
;;
*)
id="es"
;;
esac

clear

# Instalando Sistema
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "                       ⇱ INSTALANDO VPS MÁSTER ⇲"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e ""

wget -O lista https://raw.githubusercontent.com/SINNOMBRE22/master-vps/master/lista -o /dev/null

if [[ $? -eq 0 ]]; then
   valid_fun
else
   error_fun
fi
