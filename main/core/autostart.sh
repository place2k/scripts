#!/usr/bin/zsh

start() {
  local execname=$1 wname=${2:-${(C)1}} execdir=$3; [[ -n $4 ]] && export $4
  /usr/${execdir:-bin}/$execname &>/dev/null &!
  sleep 1
  qdbus org.kde.KWin /component/kwin org.kde.kglobalaccel.Component.invokeShortcut 'Window Close'
}

start kwalletmanager5 Wallet
start todoist
start spotify.sh Spotify local/scripts
start wireguard-gui WireGuard '' WEBKIT_DISABLE_DMABUF_RENDERER=1

