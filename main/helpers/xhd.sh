#!/bin/sh
((UID)) && exit 1

is_mounted() { grep -q /mnt/xhd /proc/mounts; }

case $1 in
  -m)
    if ! is_mounted; then
      cryptsetup open /dev/disk/by-uuid/176dac83-cfee-4d6c-9eab-051ce57268ba xhd -d /etc/luks-keys/xhd || exit 1
      mount /mnt/xhd
    else
      exit 1
    fi
    ;;
  -u)
    if is_mounted; then
      umount -R /mnt/xhd
      cryptsetup close xhd
    else
      exit 1
    fi
    ;;
  -c) is_mounted;;
  *) exec die.sh "Invalid flag: $1"
esac