use log::{error, info};
use serde::Deserialize;
use std::env;
use std::process::Command;
use std::thread;
use std::time::Duration;

#[derive(Debug, Deserialize, Clone, PartialEq)]
struct NtlStatus {
    status: String,
    #[serde(default)]
    critical: u32,
    #[serde(default)]
    warning: u32,
}

fn poll_status() -> Option<NtlStatus> {
    match Command::new("ntl").arg("tray").output() {
        Ok(output) => {
            let stdout = String::from_utf8_lossy(&output.stdout);
            serde_json::from_str::<NtlStatus>(&stdout).ok()
        }
        Err(e) => {
            error!("Failed to run ntl tray: {}", e);
            None
        }
    }
}

fn notify(urgency: &str, title: &str, body: &str) {
    if let Err(e) = Command::new("notify-send")
        .args(["--urgency", urgency, "--icon", "dialog-warning", title, body])
        .spawn()
    {
        error!("Failed to send notification: {}", e);
    }
}

fn main() {
    env_logger::Builder::from_env(
        env_logger::Env::default().default_filter_or("info"),
    )
    .init();

    info!("NTL Daemon starting...");

    let interval_secs: u64 = env::var("NTL_POLL_INTERVAL")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(28800);
    info!("Poll interval: {}s", interval_secs);

    let mut last: Option<NtlStatus> = None;

    loop {
        if let Some(s) = poll_status() {
            if last.as_ref() != Some(&s) {
                info!("Status changed: {:?}", s);
                match s.status.as_str() {
                    "critical" => notify(
                        "critical",
                        "NTL Security Alert",
                        &format!("{} critical, {} warning findings", s.critical, s.warning),
                    ),
                    "warning" => notify(
                        "normal",
                        "NTL Security Warning",
                        &format!("{} warning findings", s.warning),
                    ),
                    _ => {}
                }
                last = Some(s);
            }
        }
        thread::sleep(Duration::from_secs(interval_secs));
    }
}
