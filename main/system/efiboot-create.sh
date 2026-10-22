#!/bin/sh
chkroot.sh || exit 1
[[ ! -e /sys/firmware/efi ]] && echo "$(basename $0): this script can only be run on UEFI-capable systems." >&2 && exit 1

ispresent() { grep -qF "$1" <<< "$BOOTLIST"; }
devpath()  { realpath /dev/disk/by-label/$dev | grep -Po '\D+'; }

create() {
  local name="$1" loader=$2 dev=$3 part=$4

  [[ -n $dev ]] && dev=$(devpath)

  if $CLEARED || ! ispresent "$name"; then
    efibootmgr -qcd ${dev:-/dev/nvme0n1} -p ${part:-1} -L "$name" -l "$loader" || exit 1
    CREATED+=("$name")
  fi
}

CLEARED=false
BOOTLIST=""
CREATED=()

if [[ $1 == clear ]]; then
  CLEARED=true
  for n in {0..10}; do efibootmgr -qBb$n 2>/dev/null; done
else
  BOOTLIST="$(efibootmgr 2>&1 | tail -n+4 | sed 's/ch Li/chLi/' | awk '{print $2}' | sed 's/chLi/ch Li/')"
fi

create Arch\ Linux archlinux.efi
create Fallback    archlinux-fallback.efi
create Recovery    EFI/arch/grubx64.efi RECBOOT
create Ventoy      EFI/BOOT/BOOTX64.EFI Ventoy 2
create Memtest64+  EFI/MEMTEST Ventoy 2
create EFI\ Shell  EFI/SHELL Ventoy 2
create Power\ off  poweroff.efi
create Reboot      reboot.efi

efibootmgr -qo 0,1,2,3,4,5,6,7

CREATED_CNT=${#CREATED[@]}

if ((CREATED_CNT)); then
  CREATED_STR="'${CREATED[0]}'"
  LAST_CREATED=$((CREATED_CNT-1))

  for (( i=1; i<CREATED_CNT; i++ )); do
    NAME="'${CREATED[$i]}'"
    ((i==LAST_CREATED)) && CREATED_STR+=", and $NAME" || CREATED_STR+=", $NAME"
  done

  efibootmgr
  printf '\n%s: %d new entr%s created: %s.\n' $(basename $0) $CREATED_CNT $( ((CREATED_CNT == 1)) && printf y || printf ies ) "$CREATED_STR"
else
  echo "$(basename $0): no new entries created."
fi
