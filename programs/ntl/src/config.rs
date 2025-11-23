use std::collections::HashSet;

pub const LOCALHOST_V4: &str = "127.0.0.1";
pub const LOCALHOST_V6: &str = "::1";
pub const BLOCKED_IP: &str = "0.0.0.0";

pub const SUSPICIOUS_PORTS: &[u16] = &[
    4444,   // Metasploit default
    1337,   // Leet
    6667,   // IRC (often used by botnets)
    31337,  // Back Orifice
    12345,  // Netbus
    5555,   // Android ADB (sometimes exposed)
];

// Returns a Set of process names that should NEVER run as root/privileged
pub fn suspicious_process_names() -> HashSet<&'static str> {
    [
        "nc", "netcat", "ncat", "socat", 
        "curl", "wget", "python", "perl", "ruby"
    ].into()
}

// Returns a Set of shell names to watch for reverse connections
pub fn shell_names() -> HashSet<&'static str> {
    ["sh", "bash", "zsh", "dash", "ksh", "fish"].into()
}

// Returns a Set of known telemetry/spyware domains
pub fn spy_domains() -> HashSet<&'static str> {
    [
        // Microsoft / Windows
        "mobile.events.data.microsoft.com",
        "vortex.data.microsoft.com",
        // Chat Apps
        "telemetry.discordapp.com",
        "stats.slack.com",
        // Google / Analytics
        "google-analytics.com",
        "ssl.google-analytics.com",
        // Apple
        "metrics.icloud.com",
        // Generic Tracking APIs
        "api.segment.io",
        "heapanalytics.com",
        "telemetry.sdk.in"
    ].into()
}
