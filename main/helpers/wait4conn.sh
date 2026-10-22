#!/usr/bin/bash
ping() { /usr/bin/ping -c $COUNT -W $TIMEOUT -q archlinux.org &>/dev/null; }

COUNT=1
SECS=5
TIMEOUT=10
SCRIPT=$(basename $0)

#set -ex

while [[ ${1:0:1} == - ]]; do
  FLAG=${1:1:1}
  declare ARG=$2 N=2; [[ ${#1} > 2 ]] && declare ARG=${1:2} N=1
  case $FLAG in
    c) COUNT=$ARG;;
    s) SECS=$ARG;;
    t) TIMEOUT=$2;;
    *) echo "Usage: $(basename $0) [-c COUNT | -s SECONDS | -t TIMEOUT] [PROGRAM [ARGUMENTS...]]" >&2; exit 1;;
  esac
  shift $N
done

if ! ping; then
  sleep $SECS

  if ! ping; then
    echo "$SCRIPT: Waiting for connectivity..." >&2
    until ping; do sleep $SECS; done
    echo "$SCRIPT: Network reconnected!" >&2
  fi
fi

(( $# )) && exec "$@" || exit 0

