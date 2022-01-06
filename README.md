# Minimal Roottask for Hedron in Rust
This repository shows how to build and start a minimal roottask written in Rust on Hedron.

Hedron is an Open Source Microhypervisor developed at Cyberus Technology GmbH.
More Information: https://github.com/cyberus-technology/hedron

The roottask is not compatible with [NOVA](https://github.com/udosteinberg/NOVA), because it uses a
Hedron-specific syscall. However, the build process would be the same.

During my time at Cyberus Technology GmbH, I developed a new small runtime environment from
scratch written in Rust for the Hedron Microhypervisor. Because I learned so, so much and
I love to share my knowledge, I outsourced the minimal roottask to this GitHub project.

I developed this project with a Linux system. It might also build on other UNIX-systems, as long as you are on x86_64.

## Checkout
- checkout this repository
- initialize the submodule (the Hedron Microhypervisor) \
  `$ git submodule update --recursive --init`

## Build
For Hedron, please check out the build advises in the [Hedron README](https://github.com/cyberus-technology/hedron#readme).
For the roottask, you need Cargo and Rust. If you have that, you can execute: \
`$ ./build.sh`

If something fails, for example one package is missing, I'm confident that you are capable of solving this easily.

## Running
You need `QEMU` on your machine installed. If you have that, just type: \
`$ ./run_qemu.sh`

You should see the following output: \
![alt text](screenshot.png "Top: Roottask Output to Serial; Bottom: VGA Output Microhypervisor")

On the top you can see some ASCII output on the serial device from the Roottask, followed by some calculations,
that prove that floating-point operations and vector registers can be used. The second window down below shows
the QEMU window with its VGA frame buffer used by Hedron.
