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
  cargo fmt -- --check
  cargo clippy
  cd "$OLD_PWD"
}


# invoke main function
fn_main
