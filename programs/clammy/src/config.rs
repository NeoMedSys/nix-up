pub const IDLE_TIMEOUT_S: u32 = 300; // 5 minutes
pub const SLEEP_TIMEOUT_S: u32 = 600; // 10 minutes (total 15 min to sleep)
pub const LID_CLOSE_SUSPEND_DELAY_S: u64 = 20; // 20 seconds

pub const LOCK_COMMAND: &[&str] = &[
    "swaylock-effects",
    "-f",
    "--screenshots",
    "--clock",
    "--indicator",
    "--indicator-radius", "120",
    "--indicator-thickness", "8",
    "--effect-blur", "7x5",
    "--effect-vignette", "0.5:0.5",
    "--ring-color", "e94560",
    "--key-hl-color", "0f3460",
    "--line-color", "00000000",
    "--inside-color", "1a1a2e88",
    "--separator-color", "00000000",
    "--grace", "3",
    "--fade-in", "0.1"
];

// Keys for the `polling` crate event loop
pub const WAYLAND_KEY: usize = 0;
pub const COMMAND_KEY: usize = 1;
