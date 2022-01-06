use crate::hedron::capability::CapSel;

pub mod capability;
pub mod pd_ctrl;
pub mod syscall;

/// Maximum of 2^26 = 67108864 capability selectors for kernel objects.
/// Note that this number can be higher for memory capabilities!
pub const NUM_CAP_SEL: CapSel = 67108864;

pub const ROOTTASK_CAPSEL: CapSel = 32;
