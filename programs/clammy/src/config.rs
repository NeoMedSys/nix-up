use std::env;

pub fn idle_timeout_s() -> u32 {
    env::var("CLAMMY_IDLE_TIMEOUT_S")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(300)
}

pub fn sleep_timeout_s() -> u32 {
    env::var("CLAMMY_SLEEP_TIMEOUT_S")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(600)
}

pub const LID_CLOSE_SUSPEND_DELAY_S: u64 = 20;
pub const LOCK_COMMAND: &[&str] = &[
    "dms",
    "ipc",
    "call",
    "lock",
    "lock"
];
pub const WAYLAND_KEY: usize = 0;
