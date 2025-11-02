/// The command to execute to lock the screen.
/// We use `swaylock-effects` directly, as it's in the systemd service's PATH.
pub const LOCK_CMD: &str = "swaylock-effects";

// --- Timeouts (in seconds) ---

/// Timeout in seconds until displays are turned off due to inactivity.
pub const IDLE_TIMEOUT_S: u32 = 300; // 5 minutes

/// Timeout in seconds *after* idle until the system is suspended.
/// This is relative to the IDLE_TIMEOUT.
pub const SLEEP_TIMEOUT_S: u32 = 600; // 10 minutes (total 15 min to sleep)

/// Delay in seconds after lid close (with no externals) before suspending.
pub const LID_CLOSE_SUSPEND_DELAY_S: u64 = 20; // 20 seconds


// --- Internal swayidle commands ---
// These are just the strings we pass to swayidle and parse back.

pub const IDLE_EVENT_CMD: &str = "echo idle";
pub const RESUME_EVENT_CMD: &str = "echo resume";
pub const SLEEP_EVENT_CMD: &str = "echo sleep";

