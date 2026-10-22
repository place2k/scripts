#!/bin/zsh
# Remove ~/.vim/view files that do not correspond to existing files anymore (their sources have been deleted since last edit).

IFS=$'\n'
cd $HOME/.vim/view
[[ $1 == print ]] && PRINT=true || PRINT=false
typeset RMCNT=0 SZCNT=0 FSIZE FILE ORIGINAL_FILE
typeset -a FILES=($(ls))

(( $#FILES == 0 )) && echo 'No view files to process.' >&2 && exit

for FILE in $FILES; do
  ORIGINAL_FILE=${FILE:0:-1} # remove final '='
  ORIGINAL_FILE=${${ORIGINAL_FILE//\'/}//=+//} # remove single quotes and turn "=+" into '/'

  if [[ ! -e ${ORIGINAL_FILE/\~/$HOME} ]]; then
    if $PRINT; then
      echo $ORIGINAL_FILE
    else
      FSIZE=$(stat -c %s $FILE) && rm -v $FILE && (( ++RMCNT )) && SZCNT=$(( SZCNT + FSIZE ))
    fi
  fi
done

if ! $PRINT; then
  FILES=file

  (( RMCNT != 1 )) && FILES+=s
  (( RMCNT == 0 )) && RMCNT=No

  if [[ $RMCNT == No ]]; then
    SZCNT=''
  else
    if (( SZCNT >= 1048576 )); then
      NUM=$(( SZCNT / 1048576 ))
      SUF=MB
    elif (( SZCNT >= 1024 )); then
      NUM=$(( SZCNT / 1024 ))
      SUF=KB
    else
      NUM=$SZCNT
      SUF=B
    fi

    SZCNT=" ($NUM $SUF)"
  fi

  echo "$RMCNT $FILES$SZCNT removed."
fi
