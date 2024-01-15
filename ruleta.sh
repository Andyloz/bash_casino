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
  echoInfo 'Saliendo...'
  exit 1
}

function validUInt() {
  case $1 in
      '' | *[!0-9]*) return 1 ;;
      *) return 0 ;;
  esac
}

function showHelp() {
    echoInfo 'Uso del comando:'
    echo 'ruleta -m [DINERO] -t [ESTRATEGIA]'
    echoOption m 'Cantidad de dinero disponible'
    echoOption t 'Estrategia a utilizar'
    echoOption h 'Muestra esta ayuda'

    echo -e '\nEstrategias disponibles:'
    echo '  - martingala'
    echo '  - reverseLabouchere'
}

function askBetMoney() {
  local maxBet=$1
  while true; do
    echo -n "¿Con cuanto vas a empezar la apuesta? (Disponible: $maxBet €) -> "; read -r bet
    if ! validUInt "$bet"; then
      echo "Introduzca un número entero válido!!"
    elif ((maxBet < bet)); then
      echo "No puedes apostar más de $maxBet €"
    elif ((bet == 0)); then
      echo "La apuesta no puede ser de 0 €"
    else
      BET_RES="$bet"
      return
    fi
  done
}

function askBetEvenOdd() {
  while true; do
    echo -n "¿A cuál vas a apostar? (par/impar) -> "; read -r pos
    if [[ "$pos" == "par" ]]; then
      POS_RES=0
      return
    elif [[ "$pos" == "impar" ]]; then
      POS_RES=1
      return
    else
      echo "Introduzca una opción válida"
    fi
  done
}

function roulette() {
    echo $((RANDOM % 37))
}

function basicBetStatus() {
    local money_total=$1
    local money_bet=$2
    local num=$3
    echo "    Dinero total: $(tint "$c_purple" "$money_total €")"
    echo "    Apuestas $(tint "$c_purple" "$money_bet €"), te quedan $(tint "$c_purple" "$((money_total - money_bet)) €")"
    echo "    Sale el número: [$num]"
}

function martingala() {
  local money_total=$1

  askBetMoney "$money_total" # BET_RES
  local money_bet=$BET_RES
  local money_bet_init=$BET_RES
  askBetEvenOdd # POS_RES
  local even_odd_bet=$POS_RES

  local pos_s
  pos_s=$([[ $even_odd_bet == 0 ]] && echo par || echo impar)
  echo -e "\nVamos a jugar con $BET_RES € a $pos_s"
  echo -e "¡Empezamos!\n"

  while true; do
    num=$(roulette)
    basicBetStatus "$money_total" "$money_bet" "$num"

    if ((num % 2 == 0)); then
      echo "[+] Salió par"
    elif ((num % 2 == 1)); then
      echo "[-] Salió impar"
    else
      echo "[0] Salió cero"
    fi

    if ((num % 2 == even_odd_bet && num != 0)); then
      local money_win=$(((money_bet * 2)))
      echo "    $(tint "$c_green" "Ganaste") $(tint "$c_purple" "$money_win €") $(tint "$c_green" ":D")"
      ((money_total += money_win))
      tint "$c_turquoise" "    Volvemos a la apuesta inicial..."
      ((money_bet = money_bet_init))
      sleep 1
    else
      tint "$c_red" "    Perdiste :("
      ((money_total -= money_bet))
      ((money_bet *= 2))
      echo "    $(tint "$c_turquoise" "Doblamos la apuesta (")$(tint "$c_purple" "$money_bet €")$(tint "$c_turquoise" ")")"
      if ((money_total - money_bet < 0)); then
        echo
        tint "$c_red" "No tienes suficiente dinero para doblar"
        echo "Dinero final $money_total €"
        exit
      fi
    fi
    echo "    Tienes $(tint "$c_purple" "$money_total €")"

    echo
    sleep 1.2
  done
}

function reverseLabouchere() {
  echo "WIP"
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

if ! validUInt "$money"; then
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
