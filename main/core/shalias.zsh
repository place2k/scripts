#!/bin/zsh
# aliases management script to be called from .zshrc's shalias script

typeset SHALIAS_VERSION='4.0' shalias_file_name=$0

# helper functions

# TODO: auto unalias when aliases are deleted

function shalias_edit_with() {
  typeset file=$1 editor=$2 filetype=(-c 'set ft=zsh') # for vim
  typeset file_hash=$(md5sum $file | cut -d' ' -f1)

  $editor $filetype $file

  if [[ $? -eq 0 && $file_hash != $(md5sum $file | cut -d' ' -f1) ]]; then
    # TODO: shalias_update
    shalias_append cp $file $QB_DEST
    shalias_append exec zsh -l
  fi
}

function shalias_gui_edit() {
  shalias_edit_with $alias_file $GEDITOR # $alias_file instead of $1 because this function receives no arguments
}

function shalias_edit_file() {
  shalias_edit_with $1 $EDITOR
}

function shalias_edit_all() {
  for file in $alias_files[@]; do shalias_edit_file "$ZSHAL/$file"; done
  shalias_append exec zsh -l
}

function shalias_get_alias_fname() {
  local fname=$1
  for fopt in ${(k)alias_files}; do
    [[ $fname == $alias_files[$fopt] ]] && printf "$fopt" && return
  done
}

function shalias_inval_opt() {
  typeset valid_opt=$(shalias_get_alias_fname $1) inval_opt=$1
  printf 'Invalid argument: %s.' $inval_opt
  [[ -n $valid_opt ]] && printf ' Did you mean %s?' $valid_opt
  echo
}

function shalias_error() {
  echo "shalias: $1" >&2
}

function shalias_get_file() {
  local key # for invalid option error

  if [[ ! -z $arg ]]; then
    alias_file=$alias_files[$arg]
    key=$arg
  elif [[ ! -z $cmd ]]; then
    alias_file=$alias_files[$cmd]
    key=$cmd
  else
    alias_file=$DEFAULT_ALIAS_FILE
  fi

  if [[ -z $alias_file ]]; then
    shalias_help && shalias_inval_opt $key && return 1
  elif [[ $alias_file != $DEFAULT_ALIAS_FILE ]]; then
    local not_alias_file=true

    for alias_key in ${(k)alias_files}; do
      local alias_val=$alias_files[$alias_key]
      [[ $alias_file == $alias_val ]] && not_alias_file=false && break
    done

    $not_alias_file && shalias_help && shalias_error "$alias_file is not an alias file." && return 1
  fi

  alias_file="$ZSHAL/$alias_file"
}

function shalias_help() {
  echo "Shalias v$SHALIAS_VERSION - Shell aliases manager"
  echo 'Usage: shalias [command] [arguments]'
  echo

  echo 'Commands:'
  echo '1. Shalias commands:'
  echo '-c        view the shalias script code'
  echo '-m        modify the shalias script code'
  echo '-M        modify the shalias script code with the graphical text editor $GEDITOR'
  echo '-p        parse all alias files in the proper shalias-established order, according to their relevance and interdependency'
  echo '-h        show this usage message and exit'
  echo '-v        show the current version of shalias and exit'
  echo

  echo '2. Alias control commands:'
  echo '-l        list all alias files'
  echo '-L        verbosely list all alias files'
  echo "-e AN AV  set the value of alias AN to AV or, if unspecified, to the content of a pre-filled temp file edited with \$EDITOR"
  echo '          If AN/AN() does not exist, it is created and added to the end of the basic alias file'
  echo '-E AN AV  same as -e, but if AV is unspecified, the current value of AN is edited with $GEDITOR, the graphical text editor'
  echo '-s QUERY  search for an alias by its partial or full name, and print its full name, value, file, file line, and file short name'
  echo '-S QUERY  search for an alias by some part of its value, and print its full name, value, file, file line, and file short name'
  echo '-r AN...  remove the alias(es) specified by name(s) from the respective file(s), and unalias (or unfunction) it/them'
  echo

  echo '3. Alias files management commands:'
  echo '-f NAME   directly edit an alias file given by its name NAME, which may be in the long or short version (see the next command after -F)'
  echo '          If NAME is unspecified, the basic/ba file is assumed. For backwards compatibility, this is the default command when none is given'
  echo '          Therefore invoking `shalias` has the same effect as invoking `shalias -f basic` or `shalias -f ba`'
  echo '          After a successful edit, shalias will update the shell aliases accordingly, and unalias the deleted ones'
  echo '-F        edit all alias files, one after the other, sorted by parsing order'
  echo '-H NAME   show the list of short names and description for each alias file, in parsing order. If NAME is specified, show only for the file with such name'
  echo '-a FN SN  add a new alias file with name FN and shalias short name SN, open it in the text editor, and modify shalias code accordingly'
  echo '-A FN AN  add alias AN to the end of alias file FN, if the alias does not exist, and edit its value in $EDITOR. AN() specifies an alias function'
  echo '-C NAME   show the contents (with bat) of the alias file whose short name was given after this command (e.g. -v ba)'
  echo '-R NAME   remove the alias file whose short name was given after this command, and modify shalias code accordingly'
  echo '-g NAME   modify the contents of an alias file with the graphical text editor $GEDITOR'
  echo

  echo '4. Alias files commands:'
  echo 'ba        the basic alias file. Assumed if no command is given'
  echo 'pm        package management aliases'
  echo 'ls        aliases for various modes of the lsd program'
  echo 'hf        history file control aliases'
  echo 'rs        rsync aliases'
  echo 'sc        sysctl aliases'
  echo
}

function shalias_backup() {
  [[ -z $cmd || -z $alias_files[$cmd] ]] &&
  local SOURCE=$ZSHAL                    ||
  local SOURCE=$ZSHAL/$alias_files[$cmd]

  cp $SOURCE $QB_DEST
}

function shalias_backup_before_removal() {
  local BACKUP_DIR=/tmp/.shalias.bak
  test   -f $BACKUP_DIR && rm -f $_ && echo "Warning: $_ was a file and it was removed before directory creation."
  test ! -e $BACKUP_DIR && mkdir $_
  cp $alias_file   $BACKUP_DIR/$alias_files[$cmd]
  cp $shalias_file $BACKUP_DIR/$shalias_file_name.old
}

#   function init_alias_map() {
#     [[ -z $alias_map ]] && echo "$funcstack[1]: no alias map defined." >&2 && return 1
#
#     local line=1
#
#     for name_short in ${(k)alias_files}; do
#       typeset -A alias_map[$name_short]=(
#         [alias_name]=none
#         [alias_vlue]=none
#         [alias_line]=$line
#       )
#
#       local name_file=$alias_files[$name_short]
#       local path="$ZSHAL/$name_file"
#
#
#     done
#   }

function shalias_find() {
  typeset filter=$1 tofind=$2
  typeset -A alias_map

  [[ -z $tofind ]] && shalias_error "$funcstack[1]: nothing to find." && return 1

#    init_alias_map || return 1
}

function shalias_show_value() {
  local alias_name=$1
  alias $alias_name | sed -E "s/$alias_name='([^']*)'/\1/" | read alias_value
  [[ ! -z $alias_value ]] && echo "$alias_value"
}

# writer of list of commands for the parent shell
function shalias_append() {
  echo "$@" >> $shalias_cmdfile
}

# TODO: show all aliases: `als | grep -Ev '^\S*\[.+\].*$' | tr -s '\n' | sort`
# TODO: show number of aliases: as above, then `| wc -l`

# main function

function shalias_main() {
  typeset -a alias_files_short=(ba pm ls hf rs)
  typeset -a alias_files_long=(basic pkgman ls history rsync)
  typeset -A alias_files

  local shalias_file=$1
  local cmd=$2
  local arg=$3
  local DEFAULT_ALIAS_FILE=basic
  local QB_DEST=$ZSHBK/$ZSHAL_NAME
  local alias_file=none

  typeset short long

  [[ $(id -u) -eq 0 ]] && unset alias_files_{short,long}\[2\]

  for (( i=1; i<=${#alias_files_long}; ++i )); do
    short=$alias_files_short[$i]
    long=$alias_files_long[$i]

    alias_files[$short]=$long
  done

  unset short long

  # we handle commands that don't depend on alias_file first
  # to prevent commands from being used as alias file
  # names in the alias_files array, as that would cause
  # an invalid option error
  case $cmd in
  # 1. Shalias commands
  -c) bat -l zsh $shalias_file;;
  -m) spt edit sha;;
  -M) spt edit -g sha;;
  -p) for alias_file in $alias_files_long; do shalias_append source $ZSHAL/$alias_file; done;;
  -h) shalias_help;;
  -v) echo $SHALIAS_VERSION;;
  # 2. Alias control commands
  -l) dir $ZSHAL;;
  -L) lsd -lh --date=relative --size=short $ZSHAL;;
  -a) shalias_edit_all;;
  -F) shalias_find by-name  $arg;;
  -s) shalias_find by-value $arg;;
  -S) shalias_show_value    $arg;;
  -k) shalias_backup $2;;
   *)
    # now let's handle the commands that depend on the alias_file variable
    # this function accesses alias_files so we need to make sure that $cmd is not a command
    # it returns 1 on error, that's why we do this || here
    shalias_get_file || return 1
    case $cmd in
      -r)
        if [[ $(basename $alias_file) == basic ]]; then
          shalias_error "The basic alias file may not be removed."
        else
          shalias_backup_before_removal
         #unshalias $alias_file
          rm -vi $alias_file
          [[ ! -e $alias_file ]] && sed -i "/\b$arg\b/d" $shalias_file && shalias_append source $shalias_file
        fi
        ;;
      -g) shalias_gui_edit;;
      -C) bat -l zsh $alias_file;;
      *)
        if [[ $2 == -k ]]; then
          shalias_backup $1
        else
          shalias_edit_file $alias_file
        fi
        ;;
    esac
  esac
}

shalias_main $0 $1 $2
