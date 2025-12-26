pub const IDLE_TIMEOUT_S: u32 = 300; // 5 minutes
pub const SLEEP_TIMEOUT_S: u32 = 600; // 10 minutes (total 15 min to sleep)
pub const LID_CLOSE_SUSPEND_DELAY_S: u64 = 20; // 20 seconds

pub const LOCK_COMMAND: &[&str] = &[
    "dms",
    "ipc",
    "call",
    "lock",
    "lock"
];

pub const WAYLAND_KEY: usize = 0;
