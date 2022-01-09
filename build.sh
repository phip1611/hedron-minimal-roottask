#!/usr/bin/env bash

# Builds everything.

set -e
set -x

# nice "hack" which make the script work, even if not executed from "./"
DIR=$(dirname "$(realpath "$0")")
cd "$DIR" || exit

# destination directory
BUILD_DIR="./build"

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
function fn_build_rust_strip() {
  OLD_PWD=$(pwd)
  cd "./roottask" || exit
  cp "target/x86_64-unknown-hedron/debug/hmr" "target/x86_64-unknown-hedron/debug/hmr_stripped"
  strip "target/x86_64-unknown-hedron/debug/hmr_stripped"
  cp "target/x86_64-unknown-hedron/release/hmr" "target/x86_64-unknown-hedron/release/hmr_stripped"
  strip "target/x86_64-unknown-hedron/release/hmr_stripped"
  cd "$OLD_PWD"
}

# invoke main function
fn_main
