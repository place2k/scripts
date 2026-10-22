#!/usr/bin/bash
IMGDIR=/tmp/img
OUTDIR='Saved chats'
OUTPUT_FILES=()

check_dependencies() {
  local -A deps=([magick]=ImageMagick [img2pdf]='the Img2PDF converter' [ocrmypdf]='OCR My PDF')
  local -a not_installed

  for dep in ${!deps[@]}; do command -v $dep >/dev/null || not_installed+=($dep); done
  local total=${#not_installed[@]}

  if (( total )); then
    local dep nextdep=${not_installed[0]} lastcomma
    printf 'Error: '
    if (( total == 1 )); then
      printf '%s is ' "${deps[$nextdep]}"
    else
      ((total>2)) && lastcomma=,
      for ((i=1; i<=total-1; ++i)); do
        dep=$nextdep
        nextdep=${not_installed[$i]}
        printf '%s%s' "${deps[$dep]}" "$( ((i==total-1)) && echo "$lastcomma and ${deps[$nextdep]} are " || echo ", " )"
      done
    fi
    echo 'not installed.'
    exit 1
  fi
}

check_dependencies

error() { echo; echo "ERROR" >&2; exit 1; }

[[ -e $IMGDIR        ]] && echo "Error: makepdf.sh is already running." && exit 1
[[ -z $1 || $1 == -h ]] && echo 'Usage: makepdf.sh [-h|--noview] PDF IMAGES [PDF IMAGES ...]' && exit 1
mkdir -p "$IMGDIR" "$OUTDIR" || error
VIEW=true
[[ $1 == --noview ]] && VIEW=false && shift
trap "rm -r $IMGDIR" EXIT
ARGS=("$@") N=$#

for (( i=0; i<N; )) do
  OUTFILE="${ARGS[$i]}"
  OUTPUT="$OUTDIR/$OUTFILE"
  IMAGES=("${ARGS[$((++i))]}")
  COUNT=1 STATUS=0
  [[ -z "${IMAGES[0]}" || "${IMAGES[0]}" == *.pdf ]] && echo "No images provided to make $OUTFILE." >&2 && STATUS=1 && continue

  for (( ++i; i<N; ++i )); do
    [[ "${ARGS[$i]}" == *.pdf ]] && break
    IMAGES+=("${ARGS[$i]}")
  done
  for img in "${IMAGES[@]}"; do
    printf '\e[2KConverting... (%d/%d)\r' $COUNT ${#IMAGES[@]}
    magick "$img" -crop 1080x2221 +repage "$IMGDIR/$(basename "${img%.*}_%03d.png")" >/dev/null || error
    ((++COUNT))
  done
  printf '\e[2KConverting... Done\n'

  imgcount=$(ls $IMGDIR | wc -l) imgtotalsize=$(du -hs $IMGDIR | cut -d$'\t' -f1) merging='Merging %d images (%s) into %s' TEMP="$IMGDIR/$OUTFILE"
  printf "$merging..." $imgcount $imgtotalsize "$OUTFILE"
  img2pdf --rotation=ifvalid $IMGDIR/*.png -o "$TEMP" &>/dev/null || error
  printf "\r\e[2K$merging (%s)... Done\n" $imgcount $imgtotalsize "$OUTFILE" $(du -hs "$TEMP" | cut -d$'\t' -f1)
  echo 'Applying OCR...'
  echo '--------------------------------------------------------------------------------------------------------'
  ocrmypdf --output-type pdf --fast-web-view 0 "$TEMP" "$OUTPUT" || error
  echo '--------------------------------------------------------------------------------------------------------'; echo
  rm -r "$(cut -d/ -f1 <<< ${IMAGES[*]} | uniq)" "$IMGDIR"/*
  OUTPUT_FILES+=("$OUTPUT")
done

printf "\nAll done.\n"
$VIEW && okular "${OUTPUT_FILES[@]}" &>/dev/null & disown
exit $STATUS

