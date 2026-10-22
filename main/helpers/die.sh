#!/bin/sh
[[ -z $1 || $1 == -h ]] && printf 'Usage in your script:\n  exec %1$s <message>\n  exec %1$s <errno> <message>\n' $(basename $0) && exit 1
MSG="$1"
ERRNO_MSG="$(errno $MSG 2>/dev/null)" && ERRNO_MSG="$(cut -d ' ' -f3- <<< $ERRNO_MSG)" && MSG="$2: ${ERRNO_MSG,}."
echo $MSG >&2
exit 1