#!/usr/bin/bash

prompt() {
  local n=0
  local -a VALID_OPTIONS
  for ACTION in ${ACTIONS[@]}; do
    IFS='=' read -r OPTION NAME <<< "$ACTION"
    VALID_OPTIONS+=("$OPTION")
    printf '  [%s] %s' "$OPTION" "$NAME"
    ((++n))
    ((n==4)) && { n=0; echo; } || printf ' |'
  done >&2
  ((n)) && echo >&2
  while true; do
    read -rp '> ' >&2; echo
    for VO in ${VALID_OPTIONS[@]}; do
      [[ "$REPLY" == "$VO" ]] && echo "$REPLY" && return
    done
    echo "Invalid option: \"$REPLY\". Try again." >&2
  done
}

send() {
  if $GUI_RUNNING; then
    (( EUID == 0 )) && exec t2dbar notify-send "$@" || exec notify-send "$@"
  else
    [[ -n "$ID" ]] && echo 0
    printf '[%s] %s\n' "$NAME" "$SUMM" >&2
    test -n "$BODY" && echo "$_" >&2
    [[ ${#ACTIONS[@]} -gt 0 ]] && prompt
  fi
}

declare NAME SUMM BODY
declare ICON=konsole TIME=5
declare PRIO=low ACTION ID # low prio prevents notifs from lingering around after they're shown
declare -a ACTIONS
IFS=$'\0'

#set -x

SC=$(basename $0)

for arg in $@; do
  if [[ $arg =~ (icon|time|prio|action|id)=[a-zA-Z0-9]* ]] then
    IFS='=' read -r PROP VALUE <<< $arg
    if [[ $PROP == action ]]; then
      [[ "$VALUE" != *=* ]] && VALUE+="=$VALUE"
      ACTIONS+=(-A $VALUE)
      continue
    fi
  else
    VALUE=$arg
    if [[ -z $NAME ]]; then
      PROP=name
    elif [[ -z $SUMM ]]; then
      PROP=summ
    else
      PROP=body
    fi
  fi

  declare -n SETPROP=${PROP^^}
  SETPROP=$VALUE
done

[[ -z $NAME ]] && send -u critical "$SC: NAME cannot be empty."
[[ -z $SUMM ]] && send -u critical "$SC: SUMMARY cannot be empty."

OPTIONS=( -a $NAME -i $ICON -u $PRIO -h string:desktop-entry:org.kde.konsole ${ACTIONS[@]} -t $((TIME*1000)) )
[[ -n $ID ]] && OPTIONS+=(-p -r $ID)

send ${OPTIONS[@]} $SUMM $BODY
