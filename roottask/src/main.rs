#![no_std]
#![no_main]

core::arch::global_asm!(include_str!("start.S"));

mod hedron;

use crate::hedron::capability::{Crd, CrdPortIO};
use crate::hedron::pd_ctrl::{pd_ctrl_delegate, DelegateFlags};
use crate::hedron::ROOTTASK_CAPSEL;
use core::fmt::Write;
use core::panic::PanicInfo;
use uart_16550::SerialPort;

const SERIAL_PORT: u16 = 0x3f8;

#[no_mangle]
fn rust_entry(hip_ptr: *const u64, utcb_ptr: *const u64) -> ! {
    let mut foo = enable_serial_device();
    write!(
        foo,
        "Hello World: hip_ptr={:?}, utcb_ptr:{:?}",
        hip_ptr, utcb_ptr
    )
    .unwrap();

    loop {}
}

fn enable_serial_device() -> SerialPort {
    pd_ctrl_delegate(
        ROOTTASK_CAPSEL,
        ROOTTASK_CAPSEL,
        CrdPortIO::new(SERIAL_PORT, 3),
        CrdPortIO::new(SERIAL_PORT, 3),
        DelegateFlags::new(true, false, false, true, 0),
    )
    .unwrap();
    unsafe { uart_16550::SerialPort::new(SERIAL_PORT) }
}

#[panic_handler]
fn panic_handler(_info: &PanicInfo) -> ! {
    loop {}
}
