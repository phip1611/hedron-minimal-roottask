/*
MIT License

Copyright (c) 2021 Philipp Schuster

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#![no_std]
#![no_main]
#![feature(panic_info_message)]

core::arch::global_asm!(include_str!("start.S"));

mod hedron;

use crate::hedron::capability::CrdPortIO;
use crate::hedron::pd_ctrl::{pd_ctrl_delegate, DelegateFlags};
use crate::hedron::ROOTTASK_CAPSEL;
use core::fmt::Write;
use core::panic::PanicInfo;
use core::sync::atomic::{compiler_fence, Ordering};
use uart_16550::SerialPort;

/// Default standard I/O port of the serial device on (legacy) x86 platforms.
/// On legacy BIOS systems the actual port can be found in the Bios Data Area (BDA).
/// On modern systems the serial port is usually provided by a PCI card.
/// See https://tldp.org/HOWTO/Serial-HOWTO-8.html
///
/// 0x3f8 definitely works in QEMU.
const SERIAL_PORT: u16 = 0x3f8;

/// Set's itself the permissions in the port I/O bitmap via Hedron syscall
/// and outputs something to serial.
#[no_mangle]
fn rust_entry(hip_ptr: *const u8, utcb_ptr: *const u8) -> ! {
    // demonstration that vector instructions and vector registers work
    // => no #GPF or so due to stack misalignment
    let a = [1.1, 2.2, 3.3, 4.4];
    let b = [-1.55, 22.2, 63.3, -64.4];
    let mut c = [0.0; 4];
    for i in 0..4 {
        c[i] = a[i] * b[i];
    }
    // -------------------------------------
    let mut serial = enable_serial_device();
    writeln!(
        serial,
        "Hello World from Roottask: hip_ptr={hip_ptr:?}, utcb_ptr:{utcb_ptr:?}",
    )
    .unwrap();
    writeln!(serial, "a[{:?}] * b[{:?}] = c[{:?}]", a, b, c).unwrap();

    panic!("game over")
}

/// Performs a `PD_CTRL_DELEGATE`-syscall. Roottask maps itself the permissions
/// for the serial ports. It needs ports 0x38f + the seven ports after that.
///
/// Returns the port object from [`uart_16550`].
fn enable_serial_device() -> SerialPort {
    pd_ctrl_delegate(
        ROOTTASK_CAPSEL,
        ROOTTASK_CAPSEL,
        // order 3: means 2^3 == 8 => map 8 ports at once => optimization of NOVA/Hedron syscall interface
        CrdPortIO::new(SERIAL_PORT, 3),
        CrdPortIO::new(SERIAL_PORT, 3),
        // most important boolean flag: "use hypervisor as src"
        DelegateFlags::new(true, false, false, true, 0),
    )
    .unwrap();

    // initialize the driver of the serial device behind the I/O port
    unsafe { SerialPort::new(SERIAL_PORT) }
}

// required by the Rust compiler.
#[panic_handler]
fn panic_handler(info: &PanicInfo) -> ! {
    let mut serial = enable_serial_device();
    let _ = writeln!(
        serial,
        "PANIC: {:?}",
        info.message().unwrap_or(&format_args!("<unknown>"))
    );
    loop {
        compiler_fence(Ordering::SeqCst)
    }
}
