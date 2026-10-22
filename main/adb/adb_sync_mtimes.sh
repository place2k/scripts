#!/usr/bin/bash


usage() { echo "Usage: $(basename $0) [--sdcard --end --help] LOCALDIR PHONEDIR [SUBPATH...]" && exit 1; }

[[ -z $1 ]] && usage
command -v urlnpath >/dev/null || exec die.sh "urlnpath not found in PATH"
adb_is_phone_connected.sh || exit 1


IFS=$'\n'
ENDSERVER=false
PHONE_STORAGE_PREFIX=/storage/emulated/0
DIRS=() noflags=false
for (( i=1; i<=$#; ++i )); do
  ARG=${@:$i:1}
  if [[ $ARG == -* ]] && ! $noflags; then
    case $ARG in
      --sdcard) PHONE_STORAGE_PREFIX=/storage/$(adb shell 'ls /storage | grep -Em1 '\''^[0-9A-Z]{4}-[0-9A-Z]{4}$'\''' 2>/dev/null) || exec die.sh 'Error: No SD card found.';;
      --end)    ENDSERVER=true;;
      --help)   usage;;
      --)       noflags=true;;
      *) exec die.sh "$ARG: invalid flag; only --help, --sdcard and --end are supported";;
    esac
  else
    DIRS+=($ARG)
  fi
done
[[ -z ${DIRS[0]} ]] && exec die.sh 'Local directory path needed.'
[[ -z ${DIRS[1]} ]] && exec die.sh 'Phone directory needed.'

LOCAL_DIR=${DIRS[0]}
PHONE_DIR=$(adb shell echo "$PHONE_STORAGE_PREFIX/${DIRS[1]}")


shesc() { printf '%q\n' $1; }
escape_phone_path() { shesc $(urlnpath $1); }

checkpath() {
  # $2, when given, is what the message shows: the phone dir has to be
  # addressed in its %hh spelling but reported in the spelling it was typed in.
  local path=$1 shown=${2-$1}
  local T=(test)
  [[ $path == /storage/* ]] && T=(adb shell test) path=$(shesc $path)
  ${T[@]} ! -e $path && exec die.sh ENOENT  $shown
  ${T[@]} ! -d $path && exec die.sh ENOTDIR $shown
}

touch() {
  declare PH_PATH=$1 PC_PATH=$2
  [[ $PC_PATH ]] || return
  stat -- $PC_PATH
  LOCAL_MTIME=${STAT[mtime]}
  PHONE_MTIME=$(adb shell stat -c %Y -- $PH_PATH)
  TOUCH_MTIME=$(strftime %FT%T $LOCAL_MTIME)
  (( LOCAL_MTIME != PHONE_MTIME )) && adb shell touch -cmd $TOUCH_MTIME -- $PH_PATH
}

run() {
  n=$(( RANDOM % MAXJOBS/2 ))
  for (( ; JOBS < MAXJOBS && i < MAX; ++JOBS, ++i )); do eval "$1 &"; done
  while (( n>0 && CUR < MAX )); do
    wait -n; ((++CUR,--JOBS,--n))
  done
}

progress() {
  ftime() { (( $1 < 60 )) && echo $1s || strftime '%M:%S' $1; }
  local -i fps eta pct
  fps=$((CUR/s))
  eta=$(( (MAX-CUR) / fps ))
  pct=$((CUR*100/MAX))
  printf '\e[2K\r%d/%d synced in %s (%d files/s; finishing in %s)... %d%%' $CUR $MAX $(ftime $s) $fps $(ftime $eta) $pct
}

echo 'checking paths...'
checkpath $LOCAL_DIR
checkpath $PHONE_DIR

enable -f /usr/lib/bash/stat stat

declare JOBS=0 MAXJOBS=$(($(nproc)*4)) i=0 n
declare PH_LIST=/tmp/ph.paths PC_LIST=/tmp/pc.paths
printf '' | tee $PH_LIST $PC_LIST
trap 'rm -f $PH_LIST $PC_LIST; exit' INT TERM

echo 'finding files...'

# The %hh spelling only maps one way, host -> phone, so a name read off the
# phone cannot be turned back into the host name it came from. Both sides are
# therefore scanned and then paired by the escaped name: two finds on two
# filesystems do not enumerate a directory in the same order, so pairing them by
# scan position would sync each inode against whichever one happened to land at
# the same index.
declare -a PC_PATHS PH_PATHS HOST_SUBS
declare -A PHONE_SET

# urlnpath takes many paths per call and answers one line per path, in order, so
# a whole tree costs a handful of forks rather than one per inode.
escape_many() {
  local -i i=0 n=$#
  while (( i < n )); do
    urlnpath "${@:i+1:2000}"
    i+=2000
  done
}

# What the phone holds under $1, relative to $PHONE_DIR and including $1 itself.
# ./ prefixes the start point so a subpath beginning with - is not read as an
# option, and comes back off the results.
phone_scan() {
  local p
  PHONE_SET=()
  for p in $(adb shell "cd $(shesc $PHONE_DIR) && find ./$(escape_phone_path $1)"); do
    PHONE_SET[${p#./}]=1
  done
}

# Keep the HOST_SUBS the phone has too, each paired with its in-phone spelling.
# The loop forks nothing: printf -v assigns in place and the escaping is already
# done in bulk above.
pair_up() {
  local -a ESC
  local -i i n=${#HOST_SUBS[@]}
  local q
  (( n )) || return 0
  ESC=($(escape_many "${HOST_SUBS[@]}"))
  for (( i = 0; i < n; ++i )); do
    [[ ${PHONE_SET[${ESC[i]}]} ]] || continue
    printf -v q %q $PHONE_DIR/${ESC[i]}
    PC_PATHS+=($LOCAL_DIR/${HOST_SUBS[i]}) PH_PATHS+=($q)
  done
}

if (( ${#DIRS[@]} > 2 )); then
  for SUBPATH in ${DIRS[@]:2}; do
    if adb shell test ! -e $(escape_phone_path $PHONE_DIR/$SUBPATH); then
      echo "$SUBPATH: subpath does not exist; skipping..." >&2
      continue
    fi
    # A file start point makes find print just that file, so one branch covers
    # both kinds of subpath. A subpath the phone has but the host does not
    # leaves HOST_SUBS empty and is dropped without a message of its own.
    phone_scan $SUBPATH
    HOST_SUBS=($(cd -- $LOCAL_DIR && find ./$SUBPATH 2>/dev/null))
    HOST_SUBS=(${HOST_SUBS[@]#./})
    pair_up
  done
else
  PHONE_SET=()
  for SUBPATH in $(adb shell "cd $(shesc $PHONE_DIR) && find . -mindepth 1 -printf '%P\\n'"); do
    PHONE_SET[$SUBPATH]=1
  done
  HOST_SUBS=($(cd -- $LOCAL_DIR && find . -mindepth 1 -printf '%P\n'))
  pair_up
fi
unset PHONE_SET HOST_SUBS

# Zero here covers both ways of getting there: nothing selected in the first
# place, and everything selected turning out to have no host counterpart.
checkfound() { (( MAX )) || exec die.sh 'nothing to sync'; }

declare -i MAX=${#PH_PATHS[@]}
checkfound

printf '\e[2K\rfound %d file%s to mtime-sync\n' $MAX $( ((MAX>1)) && printf %c s )
enable -f /usr/lib/bash/strftime strftime

CUR=0 JOBS=0 i=0
start=$(strftime %s)
while (( CUR < MAX )); do
  run 'touch ${PH_PATHS[i]} ${PC_PATHS[$i]}'
  s=$(( $(strftime %s) - start ))
  ((s>1)) && progress
done
wait
printf '\e[2K\rfinished syncing\n'