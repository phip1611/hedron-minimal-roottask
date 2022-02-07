#!/usr/bin/env bash

# This script starts OVMF in QEMU, which will load GRUB.
# GRUB will bootstrap Hedron via Multiboot1.

set -e

# location of OVMF files if `ovmf` package is installed (at least on debian/ubuntu)
OVMF_SYSTEM_PATH="/usr/share/OVMF"
OVMF_TMP_CPY_PATH=".ovmf_tmp"
# files are here after 'fn_prepare_ovmf`
OVMF_FW_PATH="OVMF_CODE.fd"
OVMF_VARS_PATH="OVMF_VARS.fd"

BOOT_VOLUME_DIR="./boot"

#########################################################################
# nice "hack" which make the script work, even if not executed from "./"
DIR=$(dirname "$(realpath "$0")")
cd "$DIR" || exit
#########################################################################

# main allows us to move all function definitions to the end of the file
main() {
    fn_copy_ovmf
    fn_run_qemu
}

# Copies the OVMF files from the system path into a temporary
# local path. This is necessary, because otherwise QEMU always
# fails with insufficient permissions.
fn_copy_ovmf() {
    rm -rf "$OVMF_TMP_CPY_PATH"
    mkdir "$OVMF_TMP_CPY_PATH"
    cp "$OVMF_SYSTEM_PATH/$OVMF_FW_PATH" "$OVMF_TMP_CPY_PATH/$OVMF_FW_PATH"
    cp "$OVMF_SYSTEM_PATH/$OVMF_VARS_PATH" "$OVMF_TMP_CPY_PATH/$OVMF_VARS_PATH"
}

fn_run_qemu() {
    QEMU_ARGS=(
        # Disable default devices
        # QEMU by default enables a ton of devices which slow down boot.
        "-nodefaults"

        # Use a standard VGA for graphics
        "-vga"
        "std"

        # Use a modern machine, with acceleration if possible.
        "-machine"
        "q35,accel=kvm:tcg"

        # Allocate some memory
        "-m"
        "2048M"

        # two cores
        "-smp"
        "2"

        "-cpu"
        "IvyBridge"

        # Set up OVMF
        "-drive"
        "if=pflash,format=raw,file=${OVMF_TMP_CPY_PATH}/${OVMF_FW_PATH}"
        "-drive"
        "if=pflash,format=raw,file=${OVMF_TMP_CPY_PATH}/${OVMF_VARS_PATH}"

        # Mount a local directory as a FAT partition
        "-drive"
        "format=raw,file=fat:rw:${BOOT_VOLUME_DIR}"

        # Enable serial
        #
        # Connect the serial port to the host. OVMF is kind enough to connect
        # the UEFI stdout and stdin to that port too.
        "-serial"
        "stdio"

        # Setup monitor
        "-monitor"
        "vc:1024x768"
    )

    # echo "Executing: qemu-system-x86_64 " "${QEMU_ARGS[@]}"
    qemu-system-x86_64 "${QEMU_ARGS[@]}"
}

# call main
main
