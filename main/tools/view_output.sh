#!/usr/bin/bash
gui_running && [[ "$(realpath /proc/$PPID/exe)" != /usr/bin/konsole ]] && exec konsole -e $0 $@
(( $# != 0 )) || exit 1
if [[ $1 == -v ]]; then
  args=(echo '$'$2)
  shift 2
  args+=($@)
else
  args=($@)
fi
eval "${args[@]}"
read -n1