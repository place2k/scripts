#!/bin/sh

((UID)) && exit 1

is_mounted() { grep -q /mnt/xhd /proc/mounts; }
run() { [[ -e $LOCKFILE ]] && $@ 2>/dev/null; }

LOCKFILE=/tmp/.xhdmnt.lock
case $1 in
  -m)
    if ! is_mounted && test ! -e $LOCKFILE; then
      touch $_ || exit 1
      run cryptsetup open /dev/disk/by-uuid/176dac83-cfee-4d6c-9eab-051ce57268ba xhd -d /etc/luks-keys/xhd || exit 1
      run mount /mnt/xhd || exit 1
    else exit 1
    fi
    ;;
  -u)
    if is_mounted; then
      run unlink $LOCKFILE || exit 1
      umount /mnt/xhd      || exit 1
      cryptsetup close xhd || exit 1
    else exit 1
    fi
    ;;
  -d) exec unlink $LOCKFILE 2>/dev/null;;
  -c) is_mounted;;
  *) exec die.sh "Invalid flag: $1"
esac