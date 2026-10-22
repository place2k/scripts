#!/usr/bin/bash

error() { echo "$name: $1" >&2; exit 1; }

NOROOT=false QUIET=false

while [[ ${1:0:1} == - ]]; do
  [[ $1 == --unpriv ]] && NOROOT=true && shift ||
  [[ $1 == -q       ]] && QUIET=true  && shift ||
  break
done

if $QUIET; then
  if (( EUID == 0 )); then
    $NOROOT && exit 1 || exit 0
  elif ! $NOROOT; then
    exit 1
  else
    exit 0
  fi
fi

if [[ -n $1 ]]; then
  MSG="$1"
elif $NOROOT; then
  MSG='do not run this script as root'
else
  MSG='this script needs to be run as root'
fi

read -ra cmdline < <(tr '\0' ' ' </proc/$PPID/cmdline)
name=$(basename ${cmdline[0]})
case $name in sh|bash|zsh|*csh|ksh|fish|ash|dash)
  if [[ -n ${cmdline[1]} ]]; then
    i=1; while [[ ${cmdline[$i]} == -* ]]; do ((++i)); done
    [[ ${cmdline[$((i-1))]} != -c ]] && test ${cmdline[$i]} && name=$(basename $_)
  fi
  ;;
esac

if (( EUID == 0 )); then
  $NOROOT && error "$MSG" || exit 0
elif ! $NOROOT; then
  error "$MSG"
else
  exit 0
fi

