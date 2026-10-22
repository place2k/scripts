#!/usr/bin/bash

MODE=toggle

if [[ ${1:0:1} == - ]]; then
  case ${1:1:1} in
    x) MODE=exclusive;;
    m) MODE=enable;;
    M) MODE=disable;;
    *)
      echo "USAGE: $(basename $0) -x|-h PATH..."
      echo '-m       enable: append .mp3 all non-mp3, non-txt files'
      echo '-M       disable: remove the .mp3 extension from files'
      echo '-x       exclusive toggle: enable/disable all MP3 files/folders but the given ones (if any)'
      echo '-h       show this help message and exit'
      echo 'PATH     one or more paths to the MP3 files to enable/disable; if a folder is given, all MP3 files under it are toggled'
      [[ $1 == -h ]]
      exit # exit with the status of the above test
      ;;
  esac
fi

[[ $MODE != toggle ]] && shift

IFS=$'\n'
PATHS=($@)

[[ $# == 0 ]] && PATHS=(.)

enable() {
  if [[ ! $1 =~ \.mp3$ && ! $1 =~ \.txt$ ]]; then
    mv $1{,.mp3} && echo + $1.mp3
    return 0
  else
    return 1
  fi
}

disable() {
  if [[ $1 =~ \.mp3$ ]]; then
    mv $1 ${1%.mp3} && echo - ${1%.mp3}
    return 0
  else
    return 1
  fi
}

toggle() { enable $1 || disable $1; }

find() { /usr/bin/find $1 -mindepth 1 -type f -printf '%P\n'; }


if [[ $MODE == exclusive ]]; then
  declare -A PATH_MAP
  for path in ${PATHS[@]}; do PATH_MAP[$path]=X; done

  for dir in *; do
    [[ -n ${PATH_MAP[$dir]} ]] && continue
    for file in $(find $dir); do
      [[ -n ${PATH_MAP[$dir/$file]} ]] || toggle $dir/$file
    done
  done
else
  for path in ${PATHS[@]}; do
    if [[ -d $path ]]; then
      for file in $(find $path); do
        $MODE $path/$file
      done
    else
      $MODE $path
    fi
  done
fi
