#!/usr/bin/env bash

# This script generates a bootimage for the legacy x86 boot flow. It uses GRUB 2 as boot loader
# to bootstrap Hedron.
#
# The ISO can be tested like this:
# `$ qemu-system-x86_64 -boot d -cdrom grub/legacy_x86_boot.img -m 1024 -cpu host -machine q35,accel=kvm:tcg -serial stdio`

set -e

# nice "hack" which make the script work, even if not executed from "./"
DIR=$(dirname "$(realpath "$0")")
cd "$DIR" || exit

source .config.sh

function fn_main() {
    fn_prepare_iso_dir
    fn_make_image
}

function fn_prepare_iso_dir() {
    rm -rf "${ISO_SRC_DIR}"
    # GRUB expects the config by default at /boot/grub/grub.cfg
    mkdir -p "${ISO_SRC_DIR}/boot/grub"

    cp "${GRUB_DIR}/grub.cfg" "${ISO_SRC_DIR}/boot/grub/grub.cfg"
    cp "${BENDER}" "${ISO_SRC_DIR}/bender"
    cp "${HEDRON}" "${ISO_SRC_DIR}/hedron"
    cp "${ROOTTASK}" "${ISO_SRC_DIR}/roottask"
}

function fn_make_image() {
    grub-mkrescue -o "${ISO_DEST}" "${ISO_SRC_DIR}"
    echo "'${ISO_DEST}' is the bootable image (legacy x86 boot)"
}

# invoke main function
fn_main
