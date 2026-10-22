#!/usr/bin/bash

LABEL=$(basename $PWD)
TEMP=/tmp/$LABEL
mkdir -p $TEMP

IFS=$'\n'

SONGS=($(find . -type f -name '*.mp3'))
DISABLED_SONGS=($(find . -type f ! -name '*.mp3' ! -name '*.txt'))
ALL_SONGS=(${SONGS[@]} ${DISABLED_SONGS[@]})

SIZES=()
SIZE=0
TOTAL_SIZE=0

CNT=0
MAX=${#ALL_SONGS[@]}

BAR=('[')
for _ in {1..20}; do BAR+=(' '); done
BAR+=(']')
BAR_STR="$(tr -d '\n' <<< ${BAR[*]})"

enable -f /usr/lib/bash/stat stat

for SONG in ${ALL_SONGS[@]}; do
  stat $SONG
  SIZES+=( $((${STAT[size]} / 1048576)) )
  ((TOTAL_SIZE += ${STAT[size]}))
done
((TOTAL_SIZE /= 1048576))

echo Loading files into memory...

for ((i=0; i<${#ALL_SONGS[@]}; ++i)); do
  cp --parents --preserve=all ${ALL_SONGS[$i]} $TEMP

  ((++CNT))
  PCT=$(bc <<< "scale=2; $CNT / $MAX * 100" | cut -d. -f1)
  ((PCT >= 5)) && BAR[$((PCT / 5))]='#' && BAR_STR="$(tr -d '\n' <<< ${BAR[*]})"

  ((SIZE += ${SIZES[i]}))

  printf '\r\e[K%d/%d (%dM/%dM) %s %d%%' $CNT $MAX $SIZE $TOTAL_SIZE $BAR_STR $PCT
done
echo

cd $TEMP

if (( ${#DISABLED_SONGS[@]} > 0 )); then
  echo Enabling disabled songs...
  for DSONG in ${DISABLED_SONGS[@]}; do mv $DSONG{,.mp3}; done
fi

echo Synchronizing...
RSYNC_LOG=/tmp/.rsync.log
rsync.sh --update --del ./ /mnt/ssd/backups/pendrive/$LABEL &> $RSYNC_LOG

echo Cleaning up...
cd - >/dev/null
rm -r $TEMP
echo Done.

bash -c "[[ $(stat -c %s $RSYNC_LOG) -gt 0 ]] && kwrite $RSYNC_LOG; unlink $RSYNC_LOG" & disown

