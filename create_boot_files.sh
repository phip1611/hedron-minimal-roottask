#!/usr/bin/env bash

set -e

#########################################################################
# nice "hack" which make the script work, even if not executed from "./"
DIR=$(dirname "$(realpath "$0")")
cd "$DIR" || exit
#########################################################################

# destination directory
BOOT_DIR="./boot"


fn_main() {
    grub-mkstandalone -O x86_64-efi -o "${BOOT_DIR}/EFI/BOOT/BOOTX64.EFI" \
        "/boot/grub/grub.cfg=boot/BOOT/GRUB/grub.cfg"
    # grub-mkstandalone -O i386.pc -o "${BOOT_DIR}boot.iso"
}


fn_main
