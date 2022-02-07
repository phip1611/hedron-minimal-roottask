#!/usr/bin/env bash

# This script starts the Hedron Microhypervisor via Multiboot1 in QEMU
# and gives the binary of the roottask as first multiboot1 boot module
# along. Hedron will take the first boot module, extract it as ELF file
# and start it.

set -e

# make sure that this copy is up-to-date!
HEDRON="hedron/build/src/hypervisor.elf32"

# "debug" or "release"
RELEASE=release

# load stripped binary: debug symbols not relevant anyway but this
# accelerates QEMU startup by a second or so
ROOTTASK="roottask/target/x86_64-unknown-hedron/${RELEASE}/hmr_stripped"

#########################################################################
# nice "hack" which make the script work, even if not executed from "./"
DIR=$(dirname "$(realpath "$0")")
cd "$DIR" || exit
#########################################################################

# QEMU is very slow with loading multiboot files with version <6.1 or so
# therefore I strip the binary
# strip "$ROOTTASK"

# main allows us to move all function definitions to the end of the file
main() {

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
        # make sure that this is never older than the architecture the build of the roottask or Hedron targets
        # (i.e. QEMU may doesn't know SSE4 instruction but roottask uses them)
        # Additional feature flags might be required on older Hardware despite the
        # fact that they come with "Ivy Bridge".
        "IvyBridge,+x2apic,+tsc-deadline,+avx,+f16c,"

        # Multiboot1 kernel
        "-kernel"
        "${HEDRON}"

        # QEMU passes this as Multiboot1 Modules to Hedron. Multiple modules are separated
        # by a comma. The text after the path is the "cmdline" string of the boot module.
        "-initrd"
        "${ROOTTASK} roottask"

        # Enable serial
        #
        # Connect the serial port to the host.
        "-serial"
        "stdio"

        # Setup monitor
        "-monitor"
        "vc:1024x768"
  )

  echo "Executing: qemu-system-x86_64 " "${QEMU_ARGS[@]}"
  qemu-system-x86_64 "${QEMU_ARGS[@]}"

}

# call main
main
