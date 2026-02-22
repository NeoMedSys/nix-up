use std::collections::HashMap;
use std::io::{BufRead, BufReader};
use std::process::{Command, Stdio};

const FLATPAK_APPS: &[&str] = &[
    "com.slack.Slack",
    "com.spotify.Client",
    "com.valvesoftware.Steam",
    "com.github.IsmaelMartinez.teams_for_linux",
    "us.zoom.Zoom",
];

fn main() {
    eprintln!("niri-reaper: starting, watching for Flatpak window closes");

    let mut child = Command::new("niri")
        .args(["msg", "-j", "event-stream"])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .expect("failed to start niri event-stream");

    let stdout = child.stdout.take().expect("failed to capture stdout");
    let reader = BufReader::new(stdout);
    let mut windows: HashMap<u64, String> = HashMap::new();

    for line in reader.lines() {
        let line = match line {
            Ok(l) => l,
            Err(e) => {
                eprintln!("niri-reaper: read error: {e}");
                continue;
            }
        };

        let event: serde_json::Value = match serde_json::from_str(&line) {
            Ok(v) => v,
            Err(_) => continue,
        };

        // Initial window list
        if let Some(ws) = event.get("WindowsChanged") {
            if let Some(wins) = ws.get("windows").and_then(|w| w.as_array()) {
                windows.clear();
                for w in wins {
                    track_window(&mut windows, w);
                }
            }
        }

        // New or changed window
        if let Some(w) = event.get("WindowOpenedOrChanged") {
            if let Some(win) = w.get("window") {
                track_window(&mut windows, win);
            }
        }

        // Window closed — reap if Flatpak
        if let Some(wc) = event.get("WindowClosed") {
            if let Some(id) = wc.get("id").and_then(|i| i.as_u64()) {
                if let Some(app_id) = windows.remove(&id) {
                    if FLATPAK_APPS.contains(&app_id.as_str()) {
                        eprintln!("niri-reaper: killing flatpak {app_id} (window {id})");
                        let _ = Command::new("flatpak")
                            .args(["kill", &app_id])
                            .status();
                    }
                }
            }
        }
    }

    eprintln!("niri-reaper: event stream ended, exiting");
}

fn track_window(map: &mut HashMap<u64, String>, w: &serde_json::Value) {
    if let (Some(id), Some(app_id)) = (
        w.get("id").and_then(|i| i.as_u64()),
        w.get("app_id").and_then(|a| a.as_str()),
    ) {
        map.insert(id, app_id.to_string());
    }
}
