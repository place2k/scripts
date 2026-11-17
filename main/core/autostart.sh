#!/usr/bin/zsh

start() {
  close() { sleep 0.5; qdbus org.kde.KWin /component/kwin org.kde.kglobalaccel.Component.invokeShortcut 'Window Close' }
  local execname=$1 wname=${2:-${(C)1}} execdir=$3; [[ -n $4 ]] && export $4
  /usr/${execdir:-bin}/$execname &>/dev/null &!
  close; close; close
}

/usr/bin/birdtray &>/dev/null &! sleep 2 # automatically closes its own window
start kwalletmanager5 Wallet
start todoist
start spotify.sh Spotify local/scripts
start wireguard-gui WireGuard '' WEBKIT_DISABLE_DMABUF_RENDERER=1

