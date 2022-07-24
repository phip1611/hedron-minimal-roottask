#!/usr/bin/env bash

# Builds everything.

set -e
set -x

# nice "hack" which make the script work, even if not executed from "./"
DIR=$(dirname "$(realpath "$0")")
cd "$DIR" || exit

# destination directory
BUILD_DIR="./build"
COMPILER_TARGET="x86_64-unknown-none"

function fn_main() {
  fn_build_hedron
  fn_build_rust
  fn_build_rust_strip
}

function fn_prepare_build_dir() {
  rm -rf "${BUILD_DIR}"
  mkdir -p "${BUILD_DIR}"
}

function fn_build_hedron() {
  OLD_PWD=$(pwd)
  cd "./hedron" || exit
  mkdir -p build
  cd build || exit
  cmake -DBUILD_TESTING=OFF ..
  make
  cd "$OLD_PWD"
}

function fn_build_rust() {
  OLD_PWD=$(pwd)
  cd "./roottask" || exit
  cargo build
  cargo build --release
  cargo fmt -- --check
  cargo clippy
  cd "$OLD_PWD"
}

# Strip debug symbols; much smaller ELF file. Accelerates QEMU startup by a second or so.
# The strip step is only relevant for QEMU < 6.2. In QEMU 6.2, the startup of large Multiboot2
# modules is accelerated by an order of magnitude.
function fn_build_rust_strip() {
  OLD_PWD=$(pwd)
  cd "./roottask" || exit
  cp "target/${COMPILER_TARGET}/debug/hmr" "target/${COMPILER_TARGET}/debug/hmr_stripped"
  strip "target/${COMPILER_TARGET}/debug/hmr_stripped"
  cp "target/${COMPILER_TARGET}/release/hmr" "target/${COMPILER_TARGET}/release/hmr_stripped"
  strip "target/${COMPILER_TARGET}/release/hmr_stripped"
  cd "$OLD_PWD"
}

# invoke main function
fn_main
