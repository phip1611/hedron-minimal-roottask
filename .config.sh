# Path to the Hedron artifact (after build)
export HEDRON="hedron/build/src/hypervisor.elf32"

# "debug" or "release"
export RELEASE=release
export COMPILER_TARGET="x86_64-unknown-none"
# The roottask to bootstrap
export ROOTTASK="roottask/target/${COMPILER_TARGET}/${RELEASE}/hmr_stripped"

# GRUB configuration dir
export GRUB_DIR="./grub"
# Directory with intermediate artifacts to build a bootable image
export ISO_SRC_DIR="${GRUB_DIR}/iso"
# Final bootable image file.
export ISO_DEST="${GRUB_DIR}/legacy_x86_boot.img"
