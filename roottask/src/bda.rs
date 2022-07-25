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
//! Module for the Bios Data Area (BDA). More Info: <https://www.lowlevel.eu/wiki/BIOS_Data_Area>
//!
//! This is required to find the serial port on real hardware where it might not be the default
//! I/O port at 0x3f8.

use crate::hedron::capability::{CrdMem, MemCapPermissions};
use crate::{pd_ctrl_delegate, DelegateFlags, ROOTTASK_CAPSEL};
use core::sync::atomic::{AtomicBool, Ordering};

/// Physical address of the BDA.
const BIOS_DATA_AREA_ADDRESS: u64 = 0x0400;
/// Page number of [BIOS_DATA_AREA_ADDRESS]. Here, this is physical frame 0.
const BIOS_DATA_AREA_ADDRESS_PAGE_NUM: u64 = BIOS_DATA_AREA_ADDRESS / 4096;

/// A virtual address that I use to map the BIOS Data Area to.
const DEST_ADDR: u64 = 0x1000_0000;
/// Page number of [DEST_ADDR].
const DEST_ADDR_PAGE_NUM: u64 = DEST_ADDR / 4096;

/// Stores if the mapping of the boot data area already happened.
static BDA_MAPPING_DONE: AtomicBool = AtomicBool::new(false);

/// Finds the serial port from the BIOS data area. Uses the same mechanism as Hedron does
/// internally. This doesn't work on modern UEFI boot flows by default.
pub fn get_bda<'a>() -> &'a BiosDataArea {
    if !BDA_MAPPING_DONE.load(Ordering::SeqCst) {
        map_boot_data_area();
        BDA_MAPPING_DONE.store(true, Ordering::SeqCst);
    }

    // page offset
    let page_offset = BIOS_DATA_AREA_ADDRESS & 0xfff;
    let bios_data_area = DEST_ADDR | page_offset;
    let bios_data_area = bios_data_area as *const BiosDataArea;
    let bios_data_area = unsafe { bios_data_area.as_ref() }.unwrap();

    bios_data_area
}

/// Performs a PD_CTRL_DELEGATE system call to map the memory of the BDA to [DEST_ADDR].
fn map_boot_data_area() {
    // ignore errors because it is too early to print errors.. serial device not ready
    let _ = pd_ctrl_delegate(
        ROOTTASK_CAPSEL,
        ROOTTASK_CAPSEL,
        CrdMem::new(BIOS_DATA_AREA_ADDRESS_PAGE_NUM, 0, MemCapPermissions::READ),
        CrdMem::new(DEST_ADDR_PAGE_NUM, 0, MemCapPermissions::READ),
        DelegateFlags::new(true, false, false, true, 0),
    );
}

/// Bios Data Area.
/// More Info: <https://www.lowlevel.eu/wiki/BIOS_Data_Area>
#[repr(C)]
pub struct BiosDataArea {
    pub(crate) com_1_port: u16,
    pub(crate) com_2_port: u16,
}
