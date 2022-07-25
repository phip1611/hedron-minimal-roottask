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
//! Module to enable a [log]-compatible logger that uses the serial device and
//! QEMUs debugcon device.

use crate::debugcon::{get_debugcon_port, DebugconPort};
use crate::serial::get_serial_port;
use core::fmt::Write;
use log::{Metadata, Record};
use runs_inside_qemu::runs_inside_qemu;
use uart_16550::SerialPort;

static mut LOGGER: LoggerFacade = LoggerFacade(None);

/// Initializes the logger facade. Uses the serial device for logging and the QEMU debugcon logger.
/// When this function returns, macros like `log::info!()` can be called.
pub fn init(level: log::LevelFilter) {
    let mut debugcon = runs_inside_qemu()
        .is_maybe_or_very_likely()
        .then(get_debugcon_port);

    if let Some(debugcon) = debugcon.as_mut() {
        let _ = writeln!(debugcon, "debugcon logger initialized");
    }

    let (mut serial, serial_port_num) = get_serial_port();

    let _ = writeln!(
        &mut serial,
        "serial logger initialized. Port: 0x{:x}",
        serial_port_num
    );

    let loggers = Loggers { serial, debugcon };
    unsafe {
        LOGGER.0.replace(loggers);
        let _ = log::set_logger(&LOGGER);
    }
    log::set_max_level(level);

    log::trace!("Logger Facade initialized");
}

/// Logger facade for [log::set_logger].
struct LoggerFacade(Option<Loggers>);

/// Contains the actual loggers of [LoggerFacade].
struct Loggers {
    serial: SerialPort,
    debugcon: Option<DebugconPort>,
}

impl log::Log for LoggerFacade {
    fn enabled(&self, _metadata: &Metadata) -> bool {
        true
    }

    fn log(&self, record: &Record) {
        let loggers = unsafe { LOGGER.0.as_mut().unwrap() };

        if let Some(logger) = loggers.debugcon.as_mut() {
            let _ = writeln!(
                logger,
                "[{:<5} {}@{}] {}",
                record.level(),
                record.file().unwrap_or("<unknown>"),
                record.line().unwrap_or(0),
                record.args()
            );
        }

        let _ = writeln!(
            &mut loggers.serial,
            "[{:<5}  {}@{}] {}",
            record.level(),
            record.file().unwrap_or("<unknown>"),
            record.line().unwrap_or(0),
            record.args()
        );
    }

    fn flush(&self) {}
}
