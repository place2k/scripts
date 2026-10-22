#!/usr/bin/bash

check_debug() {
  if [[ -n $DEBUG ]]; then
    local DEBUG_DIR=/tmp/jfserv
    local DEBUG_LOG=$DEBUG_DIR/debug.log
    local DSNO_FILE=$DEBUG_DIR/debug_session_no
    local -i DSNO # debug session number
    mkdir -p $DEBUG_DIR

    [[ ! -e $DSNO_FILE ]] && DSNO=1 || DSNO=$(( $(cat $DSNO_FILE) + 1 ))
    printf %d $DSNO >$DSNO_FILE

    exec 3>>$DEBUG_LOG
    BASH_XTRACEFD=3
    PS4=$'\r\n[$FUNCNAME@$LINENO] '

    (( DSNO > 1 )) && printf '\n\n' >&3
    printf '[Session: %d  |  PID: %d]\n' $DSNO $$ >&3

    DEBUG=true
  else
    DEBUG=false
  fi
}

debug()   { $DEBUG && set -x -e; }
undebug() { $DEBUG && set +x +e; }

open_fds() {
  exec 0<>$PREQ
  exec 1<>$PRES
  exec 4<>$PNCL
}

get404page() {
  get_encoded_str() {
    # base64 string of the compressed 404 page template
    # which contains a @PAGE@ placeholder to be replaced with the path to page that does not exist
    printf %s 'H4sIAAAAAAACA+1YXVObQBT9QT4knaYjfejDhQBBjQm1aJI3Pya01ZqZYkt/fr1n5SwikHUax2mnPKw5cti9ez/OXRARXySUJBDBXwk24f2vKL8fAh0EQyrV/YfLl3/pwu4j3aRf6M8LHeJyC35hPu'
    printf %s 'yxHn/w+1KHff250PvRRvG54qU+H4O00vEMeKrbm4Kfk4/7S8VxYvm4PyIf80WF5Us1n1nP8Ie0BzlTu7CfqCTGThIdA11EsNMYsx7rME6r+SXkfBP9Z/BG8Z3+nGRYmilo+LXndb4Ai/7gemItM/Zc'
    printf %s 'NOJ/wf0gE8ZjHQdKnXuKB4r3FB8gKAv4A/G81IfuwM8f84EPh238jPPV+YqnU9oLe0w+1OJf0P953vJ8DXvwf1YtKnhoXnbyMcQ5+adq73zazS8r/xp74rIl/siv4G3n8zX8BfFRHKxd+Lcl+YkL/4'
    printf %s '72tMcfmXjo9e8X2B+wng6WDvzgjPyJy/zBT9rTHn/U4wrxLzrne5dWleRf6Yik64mnyRfLR6bPsk4+8hf1ZuxpjT/0w9TnDdZvzDfTVPOvUXU2Pkc6IAlmDf8A+55UVW74c/hDqvnq9masN+hDVHTH'
    printf %s 'H/aX1Bfkf3JdicJDDxyxlPCQDwd/1OEE9YD1IuLafcPfwErOB/ODA64HfRerv0/iv6E+G6ej/qAXC9aDwUbfCzZy5IvR73Y+42n45/SvyQfTbzzqA/QMTc3YE7fqP/w1tkeGlPpew7gfwr6MXunhh2'
    printf %s 'zapn/AvwHyHfUDvYWn42vGU9jf2uO/cD8vzGy+pC780MYzYf6+l0b9p+wXp1v0/9LdVN2v/9X9yJYyH5C/s2G/XqE/99V/6WzpOH/c/7ddvu0XoZP+S7/+v3T8UW9J6qL/Q9bv//j3x9/wT9gv5k3/'
    printf %s 'Dnk+i3he7oh/TukNu/XHrrdKeVQLt+hVQv01/QB6/wnnyUurt1b/A9rTo/9Lnu9NfNvxTvS/1k+mDbxF/+vn85z9c9bAx5ZfUs9D6PmG/fQzcPH4fmzP8+jv7fPPGu8XO6z/gnq+36gP4EnJ84zhj5'
    printf %s 'wXWcjO6j9/5vkvt/5zqsTL3dV/wvPyNj2/Id/Ew+nqef97dvxx/nc6z6/Jf8X4P+P975Xjb7b+He+fo4a9I6vn5SvH3/Z/5OuV/jzK+L3iyup5uLv6b37/Ken/hbTgP/7+s2X+nu8/aI1+5v59rOSr'
    printf %s '4AvyM/bXv+ka6IXUMR/48Fa6tDi3H+i68WowGUm8/rUn/q23zp/gp/z7hb+tS5m/u/VkvNeOLX+tRnoffgP/ZjWsVBYAAA=='
  }

  local page=$1
  get_encoded_str | base64 -d | gunzip -c | sed "s|@PAGE@|$page|"
}

getfavicon() {
  get_encoded_str() {
    # a base64 string of a gzip-compressed base64 string of the favicon
    printf %s 'H4sIAAAAAAACA+1YXVObQBT9QT4knaYjfejDhQBBjQm1aJI3Pya01ZqZYkt/fr1n5SwikHUax2mnPKw5cti9ez/OXRARXySUJBDBXwk24f2vKL8fAh0EQyrV/YfLl3/pwu4j3aRf6M8LHeJyC35hPu'
    printf %s 'yxHn/w+1KHff250PvRRvG54qU+H4O00vEMeKrbm4Kfk4/7S8VxYvm4PyIf80WF5Us1n1nP8Ie0BzlTu7CfqCTGThIdA11EsNMYsx7rME6r+SXkfBP9Z/BG8Z3+nGRYmilo+LXndb4Ai/7gemItM/Zc'
    printf %s 'NOJ/wf0gE8ZjHQdKnXuKB4r3FB8gKAv4A/G81IfuwM8f84EPh238jPPV+YqnU9oLe0w+1OJf0P953vJ8DXvwf1YtKnhoXnbyMcQ5+adq73zazS8r/xp74rIl/siv4G3n8zX8BfFRHKxd+Lcl+YkL/4'
    printf %s '72tMcfmXjo9e8X2B+wng6WDvzgjPyJy/zBT9rTHn/U4wrxLzrne5dWleRf6Yik64mnyRfLR6bPsk4+8hf1ZuxpjT/0w9TnDdZvzDfTVPOvUXU2Pkc6IAlmDf8A+55UVW74c/hDqvnq9masN+hDVHTH'
    printf %s 'H/aX1Bfkf3JdicJDDxyxlPCQDwd/1OEE9YD1IuLafcPfwErOB/ODA64HfRerv0/iv6E+G6ej/qAXC9aDwUbfCzZy5IvR73Y+42n45/SvyQfTbzzqA/QMTc3YE7fqP/w1tkeGlPpew7gfwr6MXunhh2'
    printf %s 'zapn/AvwHyHfUDvYWn42vGU9jf2uO/cD8vzGy+pC780MYzYf6+l0b9p+wXp1v0/9LdVN2v/9X9yJYyH5C/s2G/XqE/99V/6WzpOH/c/7ddvu0XoZP+S7/+v3T8UW9J6qL/Q9bv//j3x9/wT9gv5k3/'
    printf %s 'Dnk+i3he7oh/TukNu/XHrrdKeVQLt+hVQv01/QB6/wnnyUurt1b/A9rTo/9Lnu9NfNvxTvS/1k+mDbxF/+vn85z9c9bAx5ZfUs9D6PmG/fQzcPH4fmzP8+jv7fPPGu8XO6z/gnq+36gP4EnJ84zhj5'
    printf %s 'wXWcjO6j9/5vkvt/5zqsTL3dV/wvPyNj2/Id/Ew+nqef97dvxx/nc6z6/Jf8X4P+P975Xjb7b+He+fo4a9I6vn5SvH3/Z/5OuV/jzK+L3iyup5uLv6b37/Ken/hbTgP/7+s2X+nu8/aI1+5v59rOSr'
    printf %s '4AvyM/bXv+ka6IXUMR/48Fa6tDi3H+i68WowGUm8/rUn/q23zp/gp/z7hb+tS5m/u/VkvNeOLX+tRnoffgP/ZjWsVBYAAA=='
  }
  get_encoded_str | base64 -d | gunzip -c
}

buildmaps() {
  local name
  for subpath in $(find $ROOT/html -type f -name '*.html' ! -name index.html ! -wholename "$ROOT/html/[0A-Z].html" -printf '/%P\n'); do
    name=$(sed -r 's|/([A-Z]/)?(.*)\.html|/\2|' <<< $subpath)
    ipathmap[$subpath]=$name
    redirmap[$name]=$subpath
  done
  ipathmap[/index.html]=/
  redirmap[/]=index.html
}

script_updated() {
  stat $JFSCRIPT
  (( STAT[mtime] > JFSMTIME ))
}

# forward a message from the nc log pipe
nclfwd() {
  __forward() {
    local flag=$1 c
    case $flag in
      -l) # listening message
        read && echo "nc: [up and running]"
        ;;
      -g) # connection/http-get message
        if read -rt1 line; then
          local -a connection=($line)
          local origin=${connection[3]}
          local srcport=${connection[4]}
          echo "nc: connected to $origin:$srcport"
        fi

        $cached && c=' (cached)'
        echo "GET $reqpath$c"
        ;;
    esac
  }
  __forward $1 <&$FNCL >&2 &
}

read_request() {
  undebug
  local c origin srcport logline getline reqline

  script_updated && kill -s QUIT $$ # autorestart
  $DEBUG || TMOUT=1

  read -r getline || return 1 # HTTP GET
  while read -r reqline && [[ "$reqline" != $'\r' ]]; do
    continue # discard remaining request lines
  done
  reqpath="$(head -n1 <<< "$getline" | cut -d' ' -f2)"
  nclfwd -g # print "GET <reqpath>" message

  rhdrs="${hdrcache[$reqpath]}"
  [[ -n "$rhdrs" ]] && cached=true || cached=false

  $DEBUG || unset TMOUT
  debug
}

get_file_path() {
  local p=$ROOT

  case "$reqpath" in
    /*.html)        p+="/html$reqpath"; redirect=true;;
    /jargon.css)    p+="$reqpath";;
    /)              p+='/html/index.html';;
    /\?gloss=[A-Z]) p+="/html/$(sed -r 's/.*=([A-Z])/\1/' <<< "$reqpath").html";;
    /graphics/*)    p+="$reqpath";;
    /favicon.ico)   printf ICON;;
    *)              p+="/html${redirmap[$reqpath]}";;
  esac

  if [[ ! -e $p ]]; then
    get404page $reqpath >$HTTP404_PAGE
    p=$HTTP404_PAGE
    exists=false
  fi

  printf %s $p
}

make_headers() {
  local code reason

  if $exists; then
    if $redirect; then
      code=301 reason=Moved\ Permanently
    else
      code=200 reason=OK
    fi
  else
    code=404 reason=Not\ Found
  fi

  printf 'HTTP/1.1 %d %s\r\n' $code $reason
  $redirect && printf 'Location: %s\r\n' ${ipathmap[$reqpath]}
  printf 'Content-Type: %s\r\n' "$ftype"
  printf 'Content-Length: %d\r\n' $flen
  printf 'Date: %s\r\n' "$fdate"
  printf 'Server: %s\r\n' "$SERVERNAME"
  printf '\r\n'
}

get_file_data() { # including metadata
  debug
  if [[ $1 == ICON ]]; then
    ftype='image/vnd.microsoft.icon; charset=binary'
    fdate=$(date -d@1072722879 -R) # same as index.html's (2003-12-29 16:34:39 UTC-2)
    flen=$(getfavicon | base64 -d | wc -c)
    binary=true
    datcache_marker=B
    getfavicon
  else
    ftype=$(file -i $1 | sed -r 's/(.*): (.*)/\2/;s/xml/html/;s/plain/css/')
    [[ $(cut -d= -f2 <<< "$ftype") == binary ]] && binary=true

    stat $1
    fdate=$(date -d@${STAT[mtime]} -R)
    flen=${STAT[size]}

    if $binary; then
      datcache_marker=B
      cat $1 | base64 -w0
    else
      cat $1
    fi
  fi
  undebug
}

make_response() {
  local exists=true redirect=false
  local fpath ftype flen fdate
  local datcache_marker=T # either 'T' if cached data is text, or 'B' if it's binary data
  binary=false

  if $cached; then
    if [[ "${rhdrs:0:12}" == 'HTTP/1.1 404' ]]; then
      rdata="$(get404page $reqpath)"
    else
      rdata="${datcache[$reqpath]}"
      [[ ${rdata:0:1} == B ]] && binary=true
      rdata="${rdata:1}"
    fi
  else
    fpath=$(get_file_path)
    rdata=$(get_file_data $fpath)
    rhdrs=$(make_headers)
    hdrcache[$reqpath]="$rhdrs"
    datcache[$reqpath]="$datcache_marker$rdata"
  fi
}

write_response() {
  if $binary; then
    cat - <(base64 -d <<< "$rdata") <<< "$rhdrs"
  else
    cat <<< "$rhdrs$rdata"
  fi
}


serve() {
  local reqpath     # requested path
  local cached      # whether the response is cached
  local binary      # whether the response data is nontextual
  local rhdrs rdata # response headers and data

  local -A hdrcache # response header cache
  local -A datcache # response data cache
  local -A ipathmap # internal path map: subpath => server path
  local -A redirmap # redirection map: server path => subpath

  buildmaps # build path maps
  nclfwd -l # print startup message
  debug

  while [[ -d $JFDIR ]]; do
    read_request || continue
    make_response
    write_response
  done
}

leave() {
  rm -rf $JFDIR
  kill $NCPID
  printf '\r\nBye!\n' >&2
  exit
}

xleave() {
  printf '\r\nThe script has been updated; let'\''s autorestart now...\n' >&2
  $DEBUG && exec $JFSCRIPT --debug || exec $JFSCRIPT
}

enable_builtins() {
  for buin in stat basename head cut; do
    enable -f /usr/lib/bash/$buin $buin
  done
}


JFSCRIPT=$0
JFSMTIME=$(stat -c %Y $JFSCRIPT)
JFSCRIPT_VER=0.1
JFVERSION=4.4.7

ROOT=$HOME/Media/docs/the-jargon-file-$JFVERSION
PORT=7470 # decimal ASCII codes for 'J' and 'F' (Jargon File)

[[ ! -d $ROOT ]]      && exec die.sh "FATAL ERROR: Server root directory ($ROOT) does not exist."
! NC=$(command -v nc) && exec die.sh 'FATAL ERROR: nc (OpenBSD NetCat) is not installed.'

clear
enable_builtins

NCVER=$($NC -h 2>&1 | head -n1 | grep -Po '[0-9.-]+')
SERVERNAME="$(basename $JFSCRIPT) $JFSCRIPT_VER (netcat $NCVER)"
JFDIR=/run/user/1000/jfserv
HTTP404_PAGE=$JFDIR/404.html

PREQ=$JFDIR/req PRES=$JFDIR/res PNCL=$JFDIR/ncl
FNCL=4
NCPID_FILE=$JFDIR/nc.pid

if [[ ! -e $JFDIR ]]; then
  mkdir $JFDIR
  mkfifo $PREQ $PRES $PNCL
  open_fds
  nc -lkvp $PORT <$PRES >$PREQ 2>$PNCL & disown
  NCPID=$!
  printf %d $NCPID > $NCPID_FILE
else
  NCPID=$(cat $NCPID_FILE)
  [[ ! -d /proc/$NCPID ]] && exec die.sh "FATAL ERROR: nc is not running (last known PID: $NCPID)."
  open_fds
fi

check_debug

trap leave     EXIT
trap xleave    QUIT
trap 'sleep 5' PIPE
serve
