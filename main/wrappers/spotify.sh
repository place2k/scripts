#!/usr/bin/bash

declare LIKED_ID=collection:tracks
declare -A PLAYLIST_ID=(
  [liked]=$LIKED_ID
  [vocaloid]=0dhVJN59HSUrY1rXJQhNDy
  [nightcore]=1WKAVXLds5GTAVC5oh19iP
  [disco]=4MOClV0gHvGTFSIwCtGQg4
  [diskowarp]=5xGTuebmRC8ggeuvKsUvcg
  [eurobeat]=0PT4PJiBkOGDVRzaE9UxFN
  [best-of-kurzgesagt]=5IzDzj8PQsUizZJQXUrpNy
  [kurzgesagt-ost]=3t2Dar7gszN6e9tv7krdAf
  [synth]=0m4yxfrznTfiRbh8ezXzm3
  [lofi]=5hgMyc3INqtfVSn5SJIO96
)

declare PLAYLIST_NAME=$(cat ~/.config/autostart-spotify.playlist 2>/dev/null || printf %s liked)

declare ID=${PLAYLIST_ID[$PLAYLIST_NAME]}
[[ -z $ID ]] && ID=$LIKED_ID
[[ $ID != $LIKED_ID ]] && ID=playlist/$ID

exec /opt/spotify/spotify --uri=spotify:$ID