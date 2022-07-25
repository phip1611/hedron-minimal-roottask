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
//! Module that enables the usage of the serial device/the serial port/the COM1 port.

use crate::{bda, pd_ctrl_delegate, CrdPortIO, DelegateFlags, ROOTTASK_CAPSEL};
use core::sync::atomic::{AtomicBool, Ordering};
use uart_16550::SerialPort;

/// Default port of the serial device / COM1 port.
const DEFAULT_COM1_PORT: u16 = 0x3f8;

/// Stores if the mapping of the rights delegation of the I/O ports already happened.
static PORT_DELEGATION_DONE: AtomicBool = AtomicBool::new(false);

/// Returns a [SerialPort] object from [`uart_16550`]. In the background, the code finds the port of
/// the serial device and maps itself all rights to access the corresponding I/O ports.
pub fn get_serial_port() -> (SerialPort, u16) {
    let port = find_serial_port();

    if !PORT_DELEGATION_DONE.load(Ordering::SeqCst) {
        delegate_serial_port_rights(port);
        PORT_DELEGATION_DONE.store(true, Ordering::SeqCst);
    }

    // initialize the driver of the serial device behind the I/O port
    (unsafe { SerialPort::new(port) }, port)
}

/// Uses a PD_CTRL_DELEGATE syscall to delegate the rights for the corresponding I/O ports into
/// the I/O map of the roottask.
fn delegate_serial_port_rights(port: u16) {
    let _ = pd_ctrl_delegate(
        ROOTTASK_CAPSEL,
        ROOTTASK_CAPSEL,
        // order 3: means 2^3 == 8 => map 8 ports at once => optimization of NOVA/Hedron syscall interface
        // Background: Serial devices us behind 8 ports because it has 8 hardware registers
        CrdPortIO::new(port, 3),
        CrdPortIO::new(port, 3),
        // most important boolean flag: "use hypervisor as src"
        DelegateFlags::new(true, false, false, true, 0),
    );
}

/// Finds the serial port from the BIOS data area. Uses the same mechanism as Hedron does
/// internally. This doesn't work on modern UEFI boot flows by default.
fn find_serial_port() -> u16 {
    let bios_data_area = bda::get_bda();

    if bios_data_area.com_1_port != 0 {
        bios_data_area.com_1_port
    } else if bios_data_area.com_2_port != 0 {
        bios_data_area.com_2_port
    } else {
        DEFAULT_COM1_PORT
    }
}
