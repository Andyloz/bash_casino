#!/bin/bash

#Colours
c_green="\e[0;32m\033[1m"
c_red="\e[0;31m\033[1m"
c_blue="\e[0;34m\033[1m"
c_yellow="\e[0;33m\033[1m"
c_purple="\e[0;35m\033[1m"
c_turquoise="\e[0;36m\033[1m"
c_gray="\e[0;37m\033[1m"
c_end="\033[0m\e[0m"

function tint() {
  color=$1
  content=$2
  echo -e "$color$content$c_end"
}

function echoInfo() {
  echo -e "$(tint "$c_yellow" '[+]') $1"
}

function echoError() {
  echo -e "$(tint "$c_red" '[!]') $1"
}

function echoOption() {
  option=$1
  desc=$2
  echo -e "    $(tint "$c_purple" "$option")) $(tint "$c_gray" "$desc")"
}

function ctrlC() {
    echoInfo -e 'Saliendo...'
}

function validInt() {
  case $1 in
      '' | *[!0-9]*) return 1 ;;
      *) return 0 ;;
  esac
}

function showHelp() {
    echoInfo 'Uso del comando:'
    echo 'ruleta -m [DINERO] -t [ESTRATEGIA]'
    echoOption m 'Cantidad de dinero a apostar'
    echoOption t 'Estrategia a utilizar'
    echoOption h 'Muestra esta ayuda'

    echo -e '\nEstrategias disponibles:'
    echo '  - martingala'
    echo '  - reverseLabouchere'
}

function martingala() {

}

function reverseLabouchere() {

}

trap ctrlC INT

while getopts 'm:t:h' arg; do
  case "$arg" in
    m) money=$OPTARG ;;
    t) strategy=$OPTARG ;;
    h) showHelp; exit ;;
    *) exit ;;
  esac
done

if ! validInt "$money"; then
  echoError "Invalid money"
  exit 1
fi

if [ "$strategy" == 'martingala' ]; then
  martingala "$money"
elif [ "$strategy" == 'reverseLabouchere' ]; then
  reverseLabouchere "$money"
else
  echoError "Not valid strategy provided"
  exit 1
fi
