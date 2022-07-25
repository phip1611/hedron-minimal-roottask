/*
MIT License

Copyright (c) 2022 Philipp Schuster

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

mod bda;
mod debugcon;
mod hedron;
mod logger;
mod serial;

use crate::hedron::capability::CrdPortIO;
use crate::hedron::pd_ctrl::{pd_ctrl_delegate, DelegateFlags};
use crate::hedron::ROOTTASK_CAPSEL;
use core::panic::PanicInfo;
use core::sync::atomic::{compiler_fence, Ordering};

/// Minimal roottask that performs some calculations and prints to serial and QEMUs debugcon port.
#[no_mangle]
fn rust_entry(hip_ptr: *const u8, utcb_ptr: *const u8) -> ! {
    logger::init(log::LevelFilter::max());
    // demonstration that vector instructions and vector registers work
    // => no #GPF or so due to stack misalignment
    let a = [1.1, 2.2, 3.3, 4.4];
    let b = [-1.55, 22.2, 63.3, -64.4];
    let mut c = [0.0; 4];
    for i in 0..4 {
        c[i] = a[i] * b[i];
    }
    // -------------------------------------
    log::info!("Hello World from Roottask: hip_ptr={hip_ptr:?}, utcb_ptr:{utcb_ptr:?}");
    log::info!("a[{a:?}] * b[{b:?}] = c[{c:?}]");

    panic!("game over")
}

// required by the Rust compiler.
#[panic_handler]
fn panic_handler(info: &PanicInfo) -> ! {
    log::error!(
        "PANIC: {:?}",
        info.message().unwrap_or(&format_args!("<unknown>"))
    );
    loop {
        compiler_fence(Ordering::SeqCst)
    }
}
