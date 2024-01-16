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
    echoOption v 'Describe las jugadas'
    echoOption h 'Muestra esta ayuda'

    echo -e '\nEstrategias disponibles:'
    echo '  - martingala'
    echo '  - reverseLabouchere'
}

function askBetMoney() {
  local maxBet=$1
  while true; do
    echo -n "¿A qué deseas apostar continuamente? (Disponible: $maxBet €) -> "; read -r bet
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
    local even_odd_bet=$4

    [[ -n "$V" ]] && echo "    Dinero total: $(tint "$c_purple" "$money_total €")"
    [[ -n "$V" ]] && echo "    Apuestas $(tint "$c_purple" "$money_bet €"), te quedan $(tint "$c_purple" "$((money_total - money_bet)) €")"
    [[ -n "$V" ]] && echo "    Sale el número: [$num]"

    if ((num % 2 == 0)); then
      [[ -n "$V" ]] && echo "[+] Salió par"
    elif ((num % 2 == 1)); then
      [[ -n "$V" ]] && echo "[-] Salió impar"
    else
      [[ -n "$V" ]] && echo "[0] Salió cero"
    fi

    if ((num % 2 == even_odd_bet && num != 0)); then
      local money_win=$(((money_bet * 2)))
      [[ -n "$V" ]] && echo "    $(tint "$c_green" "Ganaste") $(tint "$c_purple" "$money_win €") $(tint "$c_green" ":D")"
    else
      [[ -n "$V" ]] && tint "$c_red" "    Perdiste :("
    fi
}

function betsSummary() {
  local money_initial=$1
  local money_total=$2
  local money_top=$3
  local play_count_total=$4
  local play_count_bad=$5
  local play_count_good=$6

  echo -n "Dinero final $money_total € "
  local money_diff
  ((money_diff = money_total - money_initial))

  local money_diff_color
  local money_diff_symbol
  if ((money_diff > 0)); then
    money_diff_color=$c_yellow
    money_diff_symbol="+"
  elif ((money_diff < 0)); then
    money_diff_color=$c_red
    money_diff_symbol=""
  fi

  if ((money_diff != 0)); then
    tint "$money_diff_color" "($money_diff_symbol$money_diff €)"
  else
    echo
  fi

  echo " $(tint "$c_yellow" "->") Cantidad en mano más grande $(tint "$c_purple" "$money_top") €"
  echo " $(tint "$c_yellow" "->") Han habido $(tint "$c_purple" "$play_count_total") jugadas "
  echo " $(tint "$c_yellow" "->") Jugadas malas: $(tint "$c_purple" "$play_count_bad")"
  echo " $(tint "$c_yellow" "->") Jugadas buenas: $(tint "$c_purple" "$play_count_good")"
}

function martingala() {
  local money_initial=$1
  local money_total=$1

  askBetMoney "$money_total" # BET_RES
  local money_bet=$BET_RES
  local money_bet_init=$BET_RES
  echo

  askBetEvenOdd # POS_RES
  local even_odd_bet=$POS_RES
  echo

  local pos_s
  pos_s=$([[ $even_odd_bet == 0 ]] && echo par || echo impar)
  echo "Vamos a jugar con $(tint "$c_purple" "$money_bet") € a $(tint "c_purple" "$pos_s")"

  if [[ -n "$V" ]]; then
    tint "$c_yellow" "¡Empezamos!"
  else
    tint "$c_gray" "Calculando jugadas..."
  fi
  echo
  tput civis

  local play_count_total=0
  local play_count_bad=0
  local play_count_good=0

  local consec_bad_plays
  consec_bad_plays=()

  local money_top=$money_total

  while true; do
    ((play_count_total++))
    if ((money_total > money_top)); then
      money_top=$money_total
    fi

    num=$(roulette)
    basicBetStatus "$money_total" "$money_bet" "$num"

    if ((num % 2 == even_odd_bet && num != 0)); then
      ((play_count_good++))
      consec_bad_plays=()
      ((money_total += money_bet * 2))
      [[ -n "$V" ]] && tint "$c_turquoise" "    Volvemos a la apuesta inicial..."
      ((money_bet = money_bet_init))
    else
      ((play_count_bad++))
      consec_bad_plays=("${consec_bad_plays[@]}" "$num")
      ((money_total -= money_bet))
      ((money_bet *= 2))
      [[ -n "$V" ]] && echo "    $(tint "$c_turquoise" "Doblamos la apuesta (")$(tint "$c_purple" "$money_bet €")$(tint "$c_turquoise" ")")"
      if ((money_total - money_bet < 0)); then
        [[ -n "$V" ]] && echo
        [[ -n "$V" ]] && tint "$c_red" "No tienes suficiente dinero para doblar"
        [[ -n "$V" ]] && echo
        break
      fi
    fi
    [[ -n "$V" ]] && echo "    Tienes $(tint "$c_purple" "$money_total €")"

    [[ -n "$V" ]] && echo
  done

  betsSummary "$money_initial" "$money_total" "$money_top" "$play_count_total" "$play_count_bad" "$play_count_good"
  echo "Jugadas malas consecutivas:"
  echo "${consec_bad_plays[@]}"

  tput cnorm
}

function reverseLabouchere() {
  local money_initial=$1
  local money_total=$1

  askBetEvenOdd # POS_RES
  local even_odd_bet=$POS_RES
  echo

  local sequence
  sequence=(1 2 3 4)
  echo "Vamos a jugar con la secuencia $(tint "c_purple" "${sequence[@]}")"

  if [[ -n "$V" ]]; then
    tint "$c_yellow" "¡Empezamos!"
  else
    tint "$c_gray" "Calculando jugadas......"
  fi
  echo
  tput civis

  local play_count_total=0
  local play_count_bad=0
  local play_count_good=0

  local money_top
  money_top=$money_total

  while true; do
    ((play_count_total++))
    if ((money_total > money_top)); then
      money_top=$money_total
    fi

    num=$(roulette)
    basicBetStatus "$money_total" "$money_bet" "$num"

    if ((num % 2 == even_odd_bet && num != 0)); then
      ((play_count_good++))
      ((money_total += money_bet * 2))
      [[ -n "$V" ]] && tint "$c_turquoise" "    Volvemos a la apuesta inicial..."
      ((money_bet = money_bet_init))
    else
      ((play_count_bad++))
      ((money_total -= money_bet))
      ((money_bet *= 2))
      [[ -n "$V" ]] && echo "    $(tint "$c_turquoise" "Doblamos la apuesta (")$(tint "$c_purple" "$money_bet €")$(tint "$c_turquoise" ")")"
      if ((money_total - money_bet < 0)); then
        [[ -n "$V" ]] && echo
        [[ -n "$V" ]] && tint "$c_red" "No tienes suficiente dinero para doblar"
        [[ -n "$V" ]] && echo
        break
      fi
    fi
    [[ -n "$V" ]] && echo "    Tienes $(tint "$c_purple" "$money_total €")"

    [[ -n "$V" ]] && echo
  done

  betsSummary "$money_initial" "$money_total" "$money_top" "$play_count_total" "$play_count_bad" "$play_count_good"
  tput cnorm
}

trap ctrlC INT

while getopts 'm:t:vh' arg; do
  case "$arg" in
    m) money=$OPTARG ;;
    t) strategy=$OPTARG ;;
    v) V="verbose" ;;
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
