#!/usr/bin/bash

input() {
  local title="$1" fmt="${2:-%s}" var=${3:-OUT} out
  until [[ -n $out ]]; do out=$(kdialog --inputbox "$title") || exit 1; done
  [[ $fmt == Year* ]] && out="${out^}"
  printf -v $var "$fmt" "$out"
}

label_dateparts() {
  get_from_archive() {
    if [[ ! -v ARLIST ]]; then
      local text='me.7z' archpath=~/Media/kink/IRL/me.7z pass
      local pass_hash=956c901742b167b8f8a093a5934e765283f1e4823cbaec8d295a6ffb8d31122d70474956eadc37f3a61a0dd91d85427ec53a38a6008379e004731762079d930f
      until [[ -n $pass ]]; do
        pass=$(kdialog --password "$text") || exit 1
        [[ "$pass_hash  -" == $(sha512sum <<< $pass) ]] || pass='' text='<b>Wrong password; try again.</b>'
      done
      declare -g ARLIST="$(7z -p$pass l ~/Media/kink/IRL/me.7z | tr -s ' ' | cut -d' ' -f6- | tail -n +21 | head -n -2)"
      unset pass
    fi

    label=$(grep -Eom1 "${dirpath//\//\[\^/\]\+/}[^/]+" <<< "$ARLIST" | sed -r "s/.*$value \(([^(]+)\).*/\1/")
  }
  save_label() { [[ -z "$label" ]] && label=EMPTY; labels[$letter$value]="$label"; }

  for part in day month year; do
    local name=$part fmt isday=true isyear=false
    [[ $part == day ]] && fmt='%s day' || name=${part^} fmt="${part^} of %s" isday=false
    local partletter=${name:0:1}
    local -n value=$part
    local dirpath=$value dirname label="${labels[$letter$value]}"

    if [[ $part == month ]]; then
      dirpath=$year/$dirpath
    elif $isday; then
      dirpath=$year/$month/$dirpath
    else
      isyear=true
    fi
    eval touch -cd $fdate'T'$time "${dirpath//\//\*/}*/" || exit 1

    if [[ -z $label ]]; then
      labeled_path=$(eval echo "$(sed 's|/|*/|g' <<< $dirpath)*/")
      test -e "$labeled_path" && label=$(basename "$labeled_path" | sed -r 's/.*\(([^(]+)\)\/?$/\1/')
    fi
    [[ -z $label ]] && get_from_archive

    if [[ -z $label ]]; then
      input "<b>Label(s) for ${name,} ${dirpath//\/-}</b><br/>Use the semicolon to separate multiple labels." "$fmt" label
      if [[ "$label" == *\;\ * ]]; then
        if $isday; then
          label=${label,,}; label=${label//;/ day;}
        else
          local -a input_labels=(${label//;/ }); label=''
          if $isyear; then
            label="Year of ${input_labels[0]^} "
            for (( i=1; i<${#input_labels[@]}-1; ++i )); do label+="${input_labels[$i]^}, "; done
            label+="and ${input_labels[$(( ${#input_labels[@]} - 1 ))]^}"
          else
            label="${input_labels[*]}"; label="${label^}"; label="${label// / month; } month"
          fi
        fi
      fi
    fi
    save_label

    dirname=$value
    [[ -n "$label" && "$label" != EMPTY ]] && dirname+=" ($label)"
    location="$dirname/$location"
  done
}

commit() {
  local year month day time; location=''

  for date in $(tr ' ' '\n' <<< ${!timestamps[*]} | sort); do
    IFS=/ read year month day <<< $date; [[ -z $day ]] && continue
    fdate=$year-$month-$day; ftime=${timestamps[$date]}; time=$(sed -r 's/(h|min)/:/g;s/s$//' <<< $ftime)
    label_dateparts

    pic=${filenames[$date-$time]}
    mkdir -p "$location" || exit 1
    touch -cd $fdate'T'$time $pic || exit 1
    mv $pic "$location[$ftime] ${filenames[$pic]}.jpg" || exit 1
  done
  timestamps=()
  filenames=()
}


[[ "$1" ]] && cd $1
declare -a PICS DATES TIMES years months days times
shopt -s nullglob
PICS=([0-9]*_[0-9]*.jpg)
[[ ${#PICS[@]} -eq 0 ]] && exec die.sh "No photos found."

PICS_LIST="$(tr ' ' '\n' <<< ${PICS[*]})"
DATES=($(cut -d_ -f1 <<< "$PICS_LIST"))
TIMES=($(cut -d_ -f2 <<< "$PICS_LIST"))

years=( $(for d in ${DATES[@]}; do echo ${d:0:4}; done))
months=($(for d in ${DATES[@]}; do echo ${d:4:2}; done))
days=(  $(for d in ${DATES[@]}; do echo ${d:6:2}; done))
times=($(
  for t in ${TIMES[@]}; do
    sed -r 's/([0-9][0-9])([0-9][0-9])([0-9][0-9])\.jpg/\1h\2min\3s/' <<< $t
  done
))

declare -A filenames timestamps labels # labels format: <date part letter><value>, e.g. Y1970, M01, d01

for (( i=0; i<${#PICS[@]}; ++i )); do
  pic=${PICS[$i]}
  year=${years[$i]} month=${months[$i]} day=${days[$i]}
  { [[ -n $lday && $lday != $day ]] || [[ -n $lmonth && $lmonth != $month ]] } && commit

  gwenview $pic &>/dev/null & GVPID=$!; sleep 0.3; trap "kill $GVPID" INT EXIT
  input 'Photo title'; filenames[$year/$month/$day-$time]=$pic; kill $GVPID; trap '' INT EXIT

  timestamps[$year]=${times[$i]}
  timestamps[$year/$month]=${times[$i]}
  timestamps[$year/$month/$day]=${times[$i]}

  lyear=$year lmonth=$month lday=$day # last date parts
done
[[ ${#filenames[@]} -gt 0 ]] && commit
