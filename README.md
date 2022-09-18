# Minimal Roottask for Hedron in Rust
This repository shows how to build and start a minimal roottask written in Rust on Hedron.

Hedron is an Open Source Microhypervisor developed at Cyberus Technology GmbH.
More Information: <https://github.com/cyberus-technology/hedron>

The roottask is not compatible with [NOVA](https://github.com/udosteinberg/NOVA), because it uses a
Hedron-specific syscall. However, the build process for a NOVA roottask would be similar.

During my time at Cyberus Technology GmbH, I developed a new small runtime environment from
scratch written in Rust for the Hedron Microhypervisor. Since I learned so, so much, and because
I love to share my knowledge, I outsourced the minimal roottask to this project.

I developed this project on a Linux system. It might also build on other UNIX-systems, as long as you are on x86_64.

## Prerequisites
This only builds in Linux environments. Maybe also in UNIX environments
such as macOS, but I didn't test it.

- [Rust and Cargo](https://www.rust-lang.org/tools/install) (to build the roottask)
- [Nix](https://nixos.org/download.html#nix-install-linux) (for Hedron)
- [QEMU](https://www.qemu.org/) (to run Hedron + roottask)

QEMU is installed best via your package manager. I recommend installing Rust via rustup,
as rustup will automatically chose the correct Rust version for the roottask.

## Checkout
- checkout this repository
- initialize the submodule (the Hedron Microhypervisor) \
  `$ git submodule update --recursive --init`

## Build & Run in QEMU
Just execute `$ ./build.sh && ./run_qemu.sh`.

If something fails, for example one package is missing, I'm confident that one should be able of
solving this easily. Probably just a missing package.

You should see something like the following output: \
![alt text](screenshot.png "Top: Roottask Output to Serial; Bottom: VGA Output Microhypervisor")

On the top you can see some ASCII output on the serial device from the Roottask, followed by some
calculations, that prove that floating-point operations and vector registers can be used. The second
window down below shows the QEMU window with its VGA frame buffer used by Hedron.

## Testing on Real Hardware
Currently, Hedron alone can only boot in legacy boot environments, i.e., non UEFI, thus BIOS, or
UEFI with CSM. You can create a bootable legacy image for x86 with the `scripts/gen_bootimage.sh`
script. It will create a bootable image in `grub/legacy_x86_boot.img` with GRUB as bootloader. You
may write this image to a USB drive and boot it.

**Technically, Hedron can boot in UEFI with a custom closed-source UEFI OS-loader at Cyberus
Technology GmbH. This is out of scope.**

The roottask will print information to the serial device (COM1 port) but not to the VGA framebuffer.
Thus, you will only see output from Hedron on the screen so far. Currently, there is no nice
mechanism to enable the roottask to print to a framebuffer. However, there are no technical
limitations for that. Just the missing implementation.
