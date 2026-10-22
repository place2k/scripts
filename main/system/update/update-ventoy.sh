#!/usr/bin/bash
chkroot.sh || exit 1

VENTOY_EFI=$(realpath /dev/disk/by-label/VTOYEFI)
VENTOY_DEV=${VENTOY_EFI:0:-1}

checkver() {
  ventoy -l $VENTOY_DEV | grep -Po '\d+\.\d+\.\d+' | \
    while read -r VER_INPKG VER_INDEV; do
      if [[ $VER_INPKG < $VER_INDEV ]]; then
        echo 'Ventoy is outdated; upgrading...' >&2
        paru -Syu --noconfirm ventoy-bin
        checkver
      else
        [[ $VER_INPKG > $VER_INDEV ]]
      fi
   done
}

die() { umount /mnt/vty; exit 1; }

checkver || exit 1

ventoy -u $VENTOY_DEV <<< y >/dev/null

mount $VENTOY_EFI /mnt/vty || exit 1
cp --preserve=timestamps /usr/share/memtest86+/memtest.efi         /mnt/vty/EFI/MEMTEST || die
cp --preserve=timestamps /usr/share/edk2-shell/x64/Shell_Full.efi  /mnt/vty/EFI/SHELL   || die
umount /mnt/vty