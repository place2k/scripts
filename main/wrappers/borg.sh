#!/usr/bin/zsh

error() {
  echo "$1" >&2
  exit 1
}

usage() {
  echo "$SCRIPT [COMMAND] [ARGUMENTS...]"
  echo 'Run borg on the home backup directory (non-root run) or the root backup one (when run as root).'
  echo 'Commands and their arguments (if any; [ARGUMENT] means an optional one; [ARGUMENT...] means a list of one or more):'
  echo 'b (break-lock)'
  echo 'k (check) [ARCHIVE]'
  echo 'c (compact)'
  echo 'd (delete) [ARCHIVE...]'
  echo 'x (extract) ARCHIVE [PATH...]'
  echo 's (extract to stdout) ARCHIVE [PATH...]'
  echo 'i (info) [ARCHIVE]'
  echo 'l (list) [ARCHIVE] [PATH...]'
  echo 'm (mount) [ARCHIVE] MOUNTPOINT [PATH...]'
  echo 'r (rename) ARCHIVE NEWNAME'
  echo 'u (umount) MOUNTPOINT'
  echo 'g (upgrade)'
  echo 'v (version)'
  echo 'h (borg help)'
  echo

  echo 'The other borg commands are not supported by the wrapper.'
  echo 'If ARCHIVE is:'
  echo '    not specified for either x, s or r, then the most recent archive is selected by default;'
  echo '    equal to either '\''first'\'' or '\''last'\'' (case-insensitive), then the corresponding archive is selected;'
  echo '    an integer, then 0 corresponds to no archive, 1 to the 1st archive, 2 selects the 2nd one, -1 the last one, -2 the 2nd-to-last, and so on;'
  echo '    equal to '\''focc'\'', then the archive is selected which has the first occurrence of the given PATH; '\''locc'\'' is used to select for the last occurrence;'
  echo '    an archive name followed by + or - and an integer, then the selected archive will be the one offset-relative to the named archive.'
  echo "If MOUNTPOINT is not given to m or u, $MOUNTPOINT is used."
}

borg_list() { $BORG list --short $@ <<< $repo[password] }

is_path() { [[ $1 == */* ]] }

arcget_occurrence() {
  search() { [[ -n $(borg_list $repo[location]::$archive $location) ]] && echo $archive > $foundfile.$archive }

  local first_index=$1 increment=$2 boundary=$3 location=$4
  local archive_first=$ARCHIVES[$first_index] archive_last=$ARCHIVES[$((first_index+maxjobs*increment))] archives=archive pos=first foundfile=/tmp/arcget_found
  local -i i=$((first_index + increment)) searched=0 jobs=0 maxjobs=$(nproc)
  local archive=$archive_first
  ((first_index==1)) || pos=last

  setopt noclobber nullglob # noclobber avoids race conditions, nullglob helps with the foundfile.* glob below
  while true; do
    printf '\e[2Ksearching archives %s through %s (%d/%d)... %d%%\r' $archive_first $archive_last $searched $arc[cnt] $((searched*100/arc[cnt])) >&2
    search 2>/dev/null &
    let i+=increment ++jobs
    (( i == boundary )) || [[ -n $(echo $foundfile.*) ]] && break
    archive=$ARCHIVES[$i]
    if ((jobs==maxjobs)); then
      let jobs=0 searched+=maxjobs
      archive_first=$archive archive_last=$ARCHIVES[$((i+maxjobs*increment))]
      wait
    fi
  done
  wait
  location="\e[2K$location"; (( searched > 1 )) && archives+=s
  (( i != boundary )) && archive=$(cat $(ls $foundfile.* | head -n1)) || unset archive
  rm -f $foundfile.*
  test $archive && printf %s $_ || error "$location: not found (all $searched $archives searched)"
  echo "$location: $pos found in archive $archive ($searched $archives searched)" >&2
}

arcget_first_occ() { arcget_occurrence 1 1 $((arc[cnt]+1)) $1 }
arcget_last_occ()  { arcget_occurrence $arc[cnt] -1 0 $1 }

arcget_offset() {
  split() {
    local arg=$1 i c
    for (( i=0; i<$#arg; ++i )); do
      c=${arg:$i:1}; [[ $c == [0-9] ]] && archive+=$c || break
    done
    offsign=${arg:$i:1}
    for (( ++i; i<$#arg; ++i )); do
      offset+=${arg:$i:1}
    done
  }

  local archive offsign offset; split
  (( offset == 0 )) && printf %s $archive && return

  local left=1 mid right=$arc[cnt] i
  while (( left < right )); do
    mid=$((right/2))
    if [[ $ARCHIVES[$mid] == $archive ]]; then
      [[ $offsign == + ]] && i=$((mid+offset)) || i=$((mid-offset))
      (( i > arc[cnt] )) && i=$arc[cnt]
      printf %s $ARCHIVES[$i]
      return
    elif [[ $ARCHIVES[$mid] < $archive ]]; then
      left=$mid
    else
      right=$mid
    fi
  done
}

arc_process() {
  local index=$1
  local archive=$cmd_args[$index]

  case ${(L)archive} in
    first) archive=$arc[first];;
    last)  archive=$arc[last];;
    focc)  archive=$(arcget_first_occ $cmd_args[$((index+1))]) || exit 1;;
    locc)  archive=$(arcget_last_occ  $cmd_args[$((index+1))]) || exit 1;;
    *)
      if [[ ! $archive =~ ^$archregex$ ]]; then
        if [[ $archive =~ ^-?[0-9]+$ ]]; then
          archive=$ARCHIVES[$archive]
        elif [[ $archive =~ ^$archregex[+-][0-9]+$ ]]; then
          local result=$(arcget_offset $archive)
          [[ -z $result ]] && echo "$archive: no archive found; ignoring..." >&2
          archive=$result
        else
          echo "warning: invalid archive ($archive); ignoring..." >&2
          unset archive
        fi
      fi
      ;;
  esac
  printf %s $archive
}


typeset SCRIPT=$(basename $0) MOUNTPOINT=/tmp/borgmp

[[ -z $1 ]] && usage && error 'No command specified.'

# in the repo array, location is for the repo's original location as-is, and path_arg is for location::archive
typeset -A kwallet=([cmd]=kwallet-query [folder]= [entry]=) repo=([location]= [path_arg]= [password]=) arc=([first]= [last]= [cnt]=)
typeset -a BORG=(/usr/bin/borg) ARCHIVES
typeset -a args=(${@:2}) borg_cmdline=($BORG) user_flags cmd_args
typeset cmd=$1 argfmt=- bplk=--bypass-lock

typeset -Ar date_re=([month]='(0[1-9]|1[0-2])' [day]='(0[1-9]|[1-2][0-9]|3[01])' [hour]='([0-1][0-9]|2[0-3])' [minsec]='[0-5][0-9][0-5][0-9]')
typeset archregex="$date_re[month]$date_re[day]"


export BORG_PASSPHRASE_FD=0


if (( EUID )); then
  repo[location]=/home.bkup
  kwallet[folder]=Vorta
  kwallet[entry]=$repo[location]
  archregex+="$date_re[hour]$date_re[minsec]"
else
  repo[location]=/bkup/repo
  kwallet[cmd]='t2dbar kwallet-query'
  kwallet[folder]=root-bkup
  kwallet[entry]=borg_passphrase
fi
repo[path_arg]=$repo[location]
repo[password]=$(eval $kwallet[cmd] -f $kwallet[folder] -r $kwallet[entry] Default)

case $cmd in
  b) borg_cmdline+=break-lock;;
  k) borg_cmdline+=(check -pv $bplk) argfmt=roa;; # argfmt=repo_or_archive
  c) borg_cmdline+=(compact -pv $bplk);;
  d) borg_cmdline+=(delete -v) argfmt=roa+;; # repo or at least one archive
  x) borg_cmdline+=(extract -pv $bplk) argfmt=ap\*;; # archive and optionally one or more paths
  s) borg_cmdline+=(extract -pv --stdout $bplk) argfmt=ap\*;;
  i) borg_cmdline+=info argfmt=roa;;
  l) borg_cmdline+=list argfmt=roap\*;; # repo or archive and optionally one or more paths
  m) borg_cmdline+=mount argfmt=mnt;; # mount-unique arg format: repo or archive, mountpoint, and optionally one or more paths
  r) borg_cmdline+=rename argfmt=ann;; # rename-unique format: archive and new name
  u) borg_cmdline+=umount argfmt=mp;; # umount format: mountpoint
  g) borg_cmdline+=(upgrade -pv);;
  v) borg_cmdline+=version;;
  h) borg_cmdline+=-h;;
  create|prune) error "Error: the $cmd command is not supported by this script. Let $kwallet[folder] handle that automatically on schedule.";;
  init) error 'Error: this script does not initialize repositories. It only handles existing ones, namely the home and the root backup ones.';;
  debug) error 'Error: this script does not debug repositories.';;
  benchmark|config|diff|export-tar|import-tar|key|recreate|serve|with-lock) error "Error: the $cmd command is not supported by this script.";;
  *) usage; error "Invalid borg command: $cmd."
esac

for arg in $args; do
  if [[ $arg[1] == - && $arg != -[0-9]* ]]; then
    user_flags+=$arg
    [[ $arg[2] == -h || ${arg:2} == help ]] && exec $BORG $borg_cmdline[-1] $arg | less -FR
  else
    cmd_args+=$arg
  fi
done
borg_cmdline+=($user_flags)

if [[ $argfmt == *a* || $argfmt == mnt ]]; then
  start=1
  typeset -i cmd_argc=$#cmd_args start
  typeset archive archive_or_path

  ARCHIVES=($(borg_list $repo[location]))
  arc[cnt]=$#ARCHIVES arc[first]=$ARCHIVES[1] arc[last]=$ARCHIVES[-1]

  if (( cmd_argc )) && ! is_path $cmd_args[1]; then
    archive=$(arc_process 1) || exit 1
    start=2
  elif [[ $argfmt != roa* ]]; then # do not escape asterisk here
    archive=$arc[last]
  else
    unset archive
  fi
  test $archive && repo[path_arg]+=::$_
fi

borg_cmdline+=$repo[path_arg]

if [[ $argfmt != - ]]; then
  case $argfmt in
    roa*|ap\*)
      mode=${argfmt:4}
      if (( cmd_argc )); then
        if [[ -n $mode || $argfmt == ap\* ]]; then
          for (( i=$start; i<=cmd_argc; ++i )); do
            archive_or_path=$cmd_args[$i]
            is_path $archive_or_path || { archive_or_path=$(arc_process $i) || exit 1 }
            borg_cmdline+=$archive_or_path
          done
        fi
      fi
      ;;
    mnt|mp)
      [[ $argfmt == mnt ]] && mparg=2 || mparg=1 # mountpoint argument index
      mntpnt=$cmd_args[$mparg]
      if [[ -z $mntpnt ]]; then
        mntpnt=$MOUNTPOINT cmd_argc+=1
      elif [[ -d $mntpnt ]]; then
        error "Mountpoint “$mntpnt” does not exist or is not a directory."
      fi
      borg_cmdline+=$mntpnt
      if [[ $argfmt == mnt ]] && (( cmd_argc > 2 )); then
        for location in ${cmd_args:2}; do
          borg_cmdline+=$location
        done
      fi
      ;;
    ann)
      (( cmd_argc != 2 )) && error '[rename] New name not provided.'
      borg_cmdline+=$cmd_args[2]
      ;;
  esac
fi

export BORG_CHECK_I_KNOW_WHAT_I_AM_DOING=YES
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

cd /
exec $borg_cmdline <<< $repo[password]