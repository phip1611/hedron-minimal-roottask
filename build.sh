#!/usr/bin/env bash

# Builds everything.

set -e
set -x

# nice "hack" which make the script work, even if not executed from "./"
DIR=$(dirname "$(realpath "$0")")
cd "$DIR" || exit 1

source .config.sh

function fn_main() {
    fn_build_hedron
    fn_build_rust
    fn_build_rust_strip
}

function fn_build_hedron() {
    cd hedron || exit 1
    # Use toolchain provided by Nix
    # I don't use "nix-build nix/release.nix -A hedron" here because this
    # way is faster because Nix needs to download less stuff.
    nix-shell --run "
    mkdir -p build
    cd build || exit 1
    cmake -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release ..
    make -j 8"
    cd ..
}

function fn_build_rust() {
    cd roottask || exit 1
    cargo check
    cargo fmt -- --check
    cargo clippy
    cargo build --release
    cd ..
}

# Strip debug symbols; much smaller ELF file. Accelerates QEMU startup by a second or so.
# The strip step is only relevant for QEMU < 6.2. In QEMU 6.2, the startup of large Multiboot2
# modules is accelerated by an order of magnitude.
function fn_build_rust_strip() {
    cd roottask || exit 1
    cp "target/${COMPILER_TARGET}/debug/hmr" "target/${COMPILER_TARGET}/debug/hmr_stripped"
    strip "target/${COMPILER_TARGET}/debug/hmr_stripped"
    cp "target/${COMPILER_TARGET}/release/hmr" "target/${COMPILER_TARGET}/release/hmr_stripped"
    strip "target/${COMPILER_TARGET}/release/hmr_stripped"
    cd ..
}

# invoke main function
fn_main
